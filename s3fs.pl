#!/usr/bin/env perl
use v5.14;
use utf8;
binmode STDOUT, ":utf8";

package S3VFS::File {
    use Moose;
    has path  => (is => "ro", isa => "Str", required => 1);
    has name  => (is => "ro", isa => "Str", required => 1);
    has mtime => (is => "ro", isa => "Int", required => 0);
    has size  => (is => "ro", isa => "Int", required => 0);
    sub is_file { 1 }
    sub is_dir  { 0 }
};

package S3VFS::Dir {
    use Moose;
    extends 'S3VFS::File';
    sub is_file { 0 }
    sub is_dir  { 1 }
};

package S3VFS {
    use POSIX qw(:errno_h);
    use Fcntl qw(:DEFAULT :mode :seek); # S_IFREG S_IFDIR, O_SYNC O_LARGEFILE etc.
    use Moose;
    use Net::Amazon::S3;
    use DateTime::Format::ISO8601;
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

        $self->fs->{"/"} = S3VFS::Dir->new(path => "/", name => "");

        $self->getdir("/");

        mkdir("/tmp/s3fscache");

        return $self;
    }

    # VFS
    sub getdir {
        my ($self, $path) = @_;
        utf8::decode($path) unless utf8::is_utf8($path);

        my $bucket = $self->bucket;

        $path =~ s{^/}{};
        $path =~ s{$}{/};

        say "GETDIR $path";

        my $prefix = $path;
        $prefix = '' if $prefix eq '/';

        my $result = $bucket->list({
            prefix    => $prefix,
            delimiter => "/"
        });

        my @ret;

        ## Dirs
        for my $item (@{$result->{common_prefixes}}) {
            my $fn = $item =~ s{^$path}{}r;
            my $f = S3VFS::Dir->new( path => "/".$item, name => $fn );
            $self->fs->{ $f->path } = $f;

            say "==> $fn";
            push @ret, $fn;
        }

        for my $item (@{$result->{keys}}) {
            my $fn = $item->{key} =~ s{^$path}{}r;
            next unless $fn;

            my $d = DateTime::Format::ISO8601->parse_datetime( $item->{last_modified} );

            my $f = S3VFS::File->new(
                path  => "/".$item->{key},
                name  => $fn,
                mtime => $d->epoch,
                size  => $item->{size}
            );
            $self->fs->{ $f->path } = $f;

            say "==> $fn";
            push @ret, $fn;
        }

        return (@ret, 0);
    }

    sub getattr {
        my ($self, $path) = @_;

        utf8::decode($path) unless utf8::is_utf8($path);

        my ($inode, $mode, $size, $mtime) = (0, 0755, 0, time-1);

        my $f = $self->fs->{$path};

        unless ($f) {
            return -ENOENT();
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
            1024,               # blocksize
            1+int($size/1024)   # blocks
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
}

package main;

use Net::Amazon::S3;
use Path::Class;
use IO::All;
use Path::Class;
use Fuse;
use YAML;

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

sub mount {
    Fuse::main(
        debug => 0,
        mountpoint => dir($mountpoint)->absolute,

        getdir => sub {
            return $s3vfs->getdir(@_);
        },

        getattr => sub {
            return $s3vfs->getattr(@_);
        },

        open => sub {
            return $s3vfs->open(@_);
        },

        read => sub {
            return $s3vfs->read(@_);
        },

        statfs => sub {
            return (90, 10240, 10240, 10240, 10240, 1024);
        }
    );
}

mount();
exit 0;
