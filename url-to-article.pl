#!/usr/bin/env perl

use v5.18;
use Firefox::Marionette;
use Mojo::DOM;
use Encode qw(encode_utf8 decode_utf8);
use HTML::ExtractContent;
use JSON qw(encode_json);
use Getopt::Long qw(GetOptions);
use MCE::Stream;

sub extract_title {
    my ($dom) = @_;
    my $title = $dom->find("title");
    return unless $title->[0];
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

my @links = map { chomp; $_ } <>;

my $log_fn = $opts{o} . "/json-feed-".timestamp().".log";

my $firefox = Firefox::Marionette->new(
    (($opts{verbose}) ? (visible => 1):()),
);

mce_stream {
    input_data => sub {
        my $uri = pop(@links) or return;

        my $html;
        MCE->say("URI: $uri");

        eval {
            $firefox->go($uri);
            $html = "" . $firefox->html;
            1;
        } or do {
            $html = '';
        };

        return [ $uri, $html ];
    }
}, sub {
    my ($uri, $html) = @$_;

    return unless $html;

    $html = decode_utf8($html) unless Encode::is_utf8($html);
    my $dom = Mojo::DOM->new($html);

    my $title = extract_title($dom);
    if (!$title) {
        MCE->sendto(
            file => encode_json({
                url => "$uri",
                error => "NO TITLE",
            })."\n",
            $log_fn
        );
        return;
    }

    my $content = extract_text_content($html);

    if (!$content) {
        MCE->sendto(
            file => encode_json({
                url => "$uri",
                error => "NO CONTENT",
            })."\n",
            $log_fn
        );
        return;
    }

    MCE->sendto(
        file => encode_json({
            url => "$uri",
            title => $title,
            content_text => $content,
        })."\n",
        $log_fn
    );
    return;
};
