#!/usr/bin/env perl

use v5.18;
use strict;
use Firefox::Marionette;
use Mojo::DOM;
use Encode qw(encode_utf8 decode_utf8);
use HTML::ExtractContent;
use JSON qw(encode_json);
use Digest::MD5 qw(md5_hex);
use Getopt::Long qw(GetOptions);
use List::Util qw(uniqstr);

sub extract_title {
    my ($dom) = @_;
    my $title = $dom->find("title");
    $title = $title->[0]->text;
    return $title;
}

sub extract_text_content {
    my ($html) = @_;
    my $extractor = HTML::ExtractContent->new;
    my $text = $extractor->extract($html)->as_text;
    if ($text !~ m/\n\n/) {
        $text =~ s/\n/\n\n/g;
    }
    return $text;
}

sub timestamp {
    my @t = localtime();
    return sprintf('%04d%02d%02d%02d%02d%02d', ($t[5]+1900), ($t[4]+1), $t[3], $t[2], $t[1], $t[0]);
}

### main

my %opts;
GetOptions(
    \%opts,
    "o=s",
    "verbose",
);

die "-o <DIR>" unless $opts{o} || (! -d $opts{o});

open my $pho, ">", $opts{o} . "/json-feed-".timestamp().".json" or die $!;
open my $log, ">", $opts{o} . "/json-feed-".timestamp().".log"  or die $!;

my $firefox = Firefox::Marionette->new(
    (($opts{verbose}) ? (visible => 1):()),
    page_load => 10_000, # 10s
);
my @links;

my %json_feed = (
    version => "https://jsonfeed.org/version/1",
    title => "Articles",
    items => [],
);

while(<>) {
    chomp;
    my $uri = URI->new($_);
    my $err;
    eval {
        $firefox->go($uri);
        1;
    } or do {
        $err = $@;
    };
    if ($err) {
        say $log "SRCERR: $uri $err";
        next;
    }

    my $html = $firefox->html;
    $html = decode_utf8($html) unless Encode::is_utf8($html);
    my $dom = Mojo::DOM->new($html);
    for my $e ($dom->find('a[href]')->each) {
        my $href = $e->attr("href");
        my $u = URI->new_abs($href, $uri);
        if ($u->scheme =~ /^http/ && $u->host eq $uri->host) {
            push @links, $u;
            say $log "URL: $u";
        }
    }
}

if (@links) {
    @links = uniqstr(@links);

    while (my $uri = pop(@links)) {
        $firefox->go($uri);
        my $html = $firefox->html;
        $html = decode_utf8($html) unless Encode::is_utf8($html);
        my $dom = Mojo::DOM->new($html);

        my $title = extract_title($dom);
        my $content = extract_text_content($html);

        if ($content) {
            push @{ $json_feed{items} }, {
                id => md5_hex(encode_utf8($uri . $title . $content)),
                url => "$uri",
                title => $title,
                content_text => $content,
            };
            say $log "ITEM: " . encode_json({
                url => "$uri",
                title => $title,
                content_text => $content,
            });
        } else {
            say $log "NO CONTENT: $uri" ;
        }
    }

    say $pho encode_json(\%json_feed);
}
