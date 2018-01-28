#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;
use List::MoreUtils qw(minmax);
use JSON::PP;
use File::Slurp qw(read_file write_file);
use Regexp::Common 'URI';
use Hijk;

use Getopt::Long qw(GetOptions);

my %opts;
GetOptions(
    \%opts,
    "dir|d=s"
);

merge_get_updates($opts{dir});

my $JSON = JSON::PP->new->utf8;
for my $merged_updates (glob("$opts{dir}/merged-getUpdates-*.json")) {
    say $merged_updates;

    my $lock = $merged_updates . ".processing";
    open my $fh, ">", $lock; close($lock);

    my $merged = $JSON->decode(scalar read_file($merged_updates));
    forward_links_to_archive($merged);

    rename( $merged_updates, $merged_updates . ".DONE" );
    unlink($lock);
}

exit;

sub merge_get_updates {
    my $dir = shift;
    my $JSON = JSON::PP->new->utf8;
    my %has_problems;
    my %updates;
    my @input = glob("${dir}/telegram-getUpdates-*.json");

    return unless @input;
    for my $f (@input) {
        my $in = read_file($f);
        my $data = $JSON->decode($in);
        if ($data->{ok}) {
            for my $m (@{$data->{result}}) {
                $updates{$m->{update_id}} = $m;
            }
        } else {
            $has_problems{$f} = 1;
        }
    }

    my $merged = {
        updates => [values %updates]
    };
    my ($min_update_id, $max_update_id) = minmax(keys %updates);
    my $t = time;
    write_file(
        "${dir}/merged-getUpdates-${min_update_id}-${max_update_id}.json",
        $JSON->encode($merged)
    );

    for my $f (@input) {
        unlink($f) unless $has_problems{$f};
    }

    return $merged;
}

sub forward_links_to_archive {
    my $res = shift;
    my @urls;
    for my $update (@{$res->{updates}}) {
        next unless $update->{message}{text};
        if ($update->{message}{text} =~ /($RE{URI}{HTTP}{-scheme => "https?"})/) {
            archive_this($1);
        }
    }
}

sub archive_this {
    my $url = shift;
    my $archivers = [
        sub {
            say "archive.is: $url";
            my $res = Hijk::request({
                method => "GET",
                host   => "archive.is",
                port   => "80",
                path   => "/submit/",
                body   => "url=$url",
                parse_chunked => 1,
            });
            return $res;
        },
        sub {
            say "web.archive.org: $url";
            my $res = Hijk::request({
                method => "GET",
                host   => "web.archive.org",
                port   => "80",
                path   => "/save/$url",
                parse_chunked => 1,
            });
            return $res;
        },
    ];

    for my $archiver (@$archivers) {
        my $kid = fork();
        unless ($kid) {
            my $res = $archiver->();
            say $res->{status}, " ", (substr( ($res->{status} =~ /^3/) ? $res->{head}{Location} : $res->{body} , 0, 64) =~ s/\n/\\n/gr);
            exit;
        }
    }
    wait() for @$archivers;
    return;
}
