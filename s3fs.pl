#!/usr/bin/env perl
use v5.14;
use utf8;
binmode STDOUT, ":utf8";

package S3VFS::File {
    use Moose;
    has name  => (is => "ro", isa => "Str", required => 1);
    has mtime => (is => "ro", isa => "Int", required => 0);
    has size  => (is => "ro", isa => "Int", required => 0);
    has parent => (is => "ro", isa => "Str", required => 1);
    has refresh_at => (
        is => "rw", isa => "Int", required => 1,
        default => sub { time }
    );
    sub is_file { 1 }
    sub is_dir  { 0 }
};

package S3VFS::Dir {
    use Moose;
    extends 'S3VFS::File';
    has '+refresh_at' => ( default => sub { 0 } );
    sub is_file { 0 }
    sub is_dir  { 1 }
};

package S3VFS {
    use Errno;
    use Fcntl qw(:DEFAULT :mode :seek); # S_IFREG S_IFDIR, O_SYNC O_LARGEFILE etc.
    use Moose;
    use Net::Amazon::S3;
    use DateTime::Format::ISO8601;
    use Path::Class;
    use Scalar::Util qw(refaddr);
    use Digest::SHA qw(sha1_hex);

    has aws_access_key => (is => "ro", isa => "Str", required => 1);
    has aws_secret_key => (is => "ro", isa => "Str", required => 1);
    has bucket_name    => (is => "ro", isa => "Str", required => 1);

    has s3 => (
        is => "ro",
        isa => "Net::Amazon::S3",
        lazy => 1,
        builder => '_build_s3'
    );

    has bucket => (
        is => "ro",
        isa => "Net::Amazon::S3::Bucket",
        lazy => 1,
        builder => '_build_bucket'
    );

    has fs => (
        is => "ro",
        isa => "HashRef",
        default => sub { {} }
    );

    # S3
    sub _build_s3 {
        my ($self) = @_;

        return Net::Amazon::S3->new({
            aws_access_key_id     => $self->aws_access_key,
            aws_secret_access_key => $self->aws_secret_key,
            retry => 1
        });
    }

    sub _build_bucket {
        my ($self) = @_;
        return $self->s3->bucket( $self->bucket_name );
    }

    sub BUILD {
        my $self = shift;

        $self->fs->{"/"} = S3VFS::Dir->new(
            parent => "",
            path   => "/",
            name   => ""
        );

        mkdir("/tmp/s3fscache");
        return $self;
    }

    sub refresh {
        my ($self, $path, $isdir) = @_;

        say "REFRESH: $path " . ($isdir ? "(DIR)" : "");

        if (my $f = $self->fs->{$path}) {
            if (time - $f->refresh_at < 6) {
                say "SKIP REFRESH: very close time frame";
                return;
            }
        }

        my $prefix = $path =~ s{^/}{}r;

        $prefix .= "/" if $isdir;
        $prefix = '' if $prefix eq '/';

        my $result = $self->bucket->list({
            prefix    => $prefix,
            delimiter => "/"
        });

        ## Dirs
        for my $item (@{$result->{common_prefixes}}) {
            my $fn = $item =~ s{^$prefix}{}r;
            next unless $fn;

            my $p = "/$item";
            my $f = S3VFS::Dir->new(
                parent => $path,
                name   => $fn
            );
            $self->fs->{ $p } = $f;
        }

        for my $item (@{$result->{keys}}) {
            my $fn = $item->{key} =~ s{^$prefix}{}r;
            next unless $fn;

            my $d = DateTime::Format::ISO8601->parse_datetime( $item->{last_modified} );

            my $p = "/".$item->{key};
            my $f = S3VFS::File->new(
                parent => $path,
                name   => $fn,
                mtime  => $d->epoch,
                size   => $item->{size}
            );
            $self->fs->{ $p } = $f;
        }

        if (my $f = $self->fs->{$path}) {
            $f->refresh_at(time);
        }

        return $self;
    }

    # VFS
    sub getdir {
        my ($self, $path) = @_;
        utf8::decode($path) unless utf8::is_utf8($path);

        say "GETDIR $path";

        $self->refresh($path, 1);

        my @ret;

        my $fs = $self->fs;
        for my $k (keys %$fs) {
            if ($fs->{$k}->parent eq $path) {
                push @ret, $fs->{$k}->name;
            }
        }

        return (@ret, 0);
    }

    sub getattr {
        my ($self, $path) = @_;
        utf8::decode($path) unless utf8::is_utf8($path);

        say "GETATTR $path";

        my ($inode, $mode, $size, $mtime) = (0, 0755, 0, time-1);

        my $f = $self->fs->{$path};

        unless ($f) {
            $self->refresh( "".file($path)->parent, 1 );
            $f = $self->fs->{$path};
        }

        unless ($f) {
            return -Errno::ENOENT();
        }

        $mode |= S_IFDIR if $f->is_dir;
        $mode |= S_IFREG if $f->is_file;

        $size  = $f->size || 0;
        $inode = refaddr($f);
        $mtime = $f->mtime;

        return (
            0,                  # device number (?)
            $inode,             # inode
            $mode,              # mode
            1,                  # nlink
            $>,                 # uid
            $)+0,               # gid
            0,                  # rdev
            $size,              # size
            0,                  # atime
            $mtime,             # mtime
            0,                  # ctime
            4096,               # blocksize
            1+int($size/4096)   # blocks
        );
    }

    sub open {
        my ($self, $path, $flags, $fileinfo) = @_;
        $path =~ s{^/}{};

        my $local_cache_file = "/tmp/s3fscache/".sha1_hex($path);

        unless (-f $local_cache_file) {
            $self->bucket->get_key_filename($path, 'GET', $local_cache_file);
        }

        my $fh;

        CORE::open($fh, "<:bytes", $local_cache_file);

        return (0, $fh);
    }


    sub read {
        my ($self, $path, $size, $offset, $fh) = @_;

        $path =~ s{^/}{};

        my $out = "";

        CORE::seek($fh, $offset, SEEK_SET);
        CORE::read($fh, $out, $size);

        return $out;
    }

    sub release {
        my ($self, $path, $flags, $fh) = @_;
        CORE::close($fh) if $fh;
    }

    sub statfs {
        my $s = 1024**3;
        return (90, $s, $s, $s, $s, 4096);
    }
}

package main;

use Fuse;
use YAML;

sub mount {
    my $s3vfs = shift;
    my $mountpoint = shift;

    my %delegates;
    for my $method (qw[getdir getattr open read release statfs]) {
        $delegates{$method} = sub { return $s3vfs->$method(@_) };
    }

    Fuse::main(
        debug => 0,
        mountpoint => $mountpoint,
        %delegates
    );
}

sub main {
    unless ($ENV{EC2_ACCESS_KEY} && $ENV{EC2_SECRET_KEY}) {
        die "export env var EC2_ACCESS_KEY and EC2_SECRET_KEY\n";
    }

    my ($bucket_name, $mountpoint) = @ARGV;

    unless ($bucket_name && $mountpoint) {
        die "Usage: s3fs.pl <bucket> <mountpoint>";
    }

    my $s3vfs = S3VFS->new(
        aws_access_key => $ENV{EC2_ACCESS_KEY},
        aws_secret_key => $ENV{EC2_SECRET_KEY},
        bucket_name    => $bucket_name
    );

    mount($s3vfs, $mountpoint);

    say YAML::Dump($s3vfs->fs);

    exit 0;
}

main();
