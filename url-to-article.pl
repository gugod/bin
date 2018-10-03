#!/usr/bin/env perl

use v5.18;
use strict;
use Firefox::Marionette;
use Mojo::DOM;
use Encode qw(encode_utf8 decode_utf8);
use HTML::ExtractContent;
use JSON qw(encode_json);
use Digest::MD5 qw(md5_hex);

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

my $firefox = Firefox::Marionette->new();
my @links;

my %json_feed = (
    version => "https://jsonfeed.org/version/1",
    title => "Articles",
    items => [],
);

while(<>) {
    chomp;
    my $uri = URI->new($_);
    $firefox->go($uri);
    my $html = $firefox->html;
    $html = decode_utf8($html) unless Encode::is_utf8($html);
    my $dom = Mojo::DOM->new($html);
    for my $e ($dom->find('a[href]')->each) {
        my $href = $e->attr("href");
        my $u = URI->new_abs($href, $uri);
        if ($u->scheme =~ /^http/ && $u->host eq $uri->host) {
            push @links, $u;            
            say STDERR "URL: $u";
        }
    }
}

while(my $uri = pop(@links)) {
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
        say STDERR encode_json({
            url => "$uri",
            title => $title,
            content_text => $content,
        });
    } else {
        say STDERR "NO CONTENT: $uri" ;
    }
}

say encode_json(\%json_feed);
