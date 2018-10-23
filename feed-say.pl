#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;

use JSON qw(encode_json);
use Encode qw(encode_utf8 decode_utf8);
use Regexp::Common qw/URI/;
use HTML::Strip;
use URI;
use XML::Feed;
use Getopt::Long;
use Unicode::UCD qw(charscript);
use List::Util qw(shuffle);

sub pick {
    $_[ rand(@_) ]
}

my %voices = (
    Han => ["Mei-Jia"],
    Hiragana => ["Kyoko", "Otoya"],
    Katagana => ["Otoya", "Kyoko"],
    Latin => ["Daniel", "Kate", "Oliver", "Serena", "Moria", "Karen", "Lee"],
);

sub guess_proper_voice {
    my ($str) = @_;
    my %freq;
    for (my $i = 0; $i < length($str); $i++) {
        my $char = substr($str, $i, 1);
        my $script = charscript(ord($char));
        $freq{$script}++;
    }
    $freq{""} = 0;
    my $mode = "";
    for(keys %freq) {
        $mode = $_ if $freq{$_} > $freq{$mode};
    }
    say encode_json(\%freq);
    return pick(@{ $voices{$mode} // $voices{Latin} });
}

sub print_and_tts {
    my ($str, $file) = @_;
    my $voice = guess_proper_voice($str);
    say("[$voice] $str\n----\n");

    open(my $fh, "| say -v \Q$voice\E");
    print $fh encode_utf8($str);
    close($fh);
}

my %opts;
GetOptions(
    \%opts,
    "o",
    "n",
);

my $striper = HTML::Strip->new;
my $i = "0000";
my $file;
binmode STDOUT, ':utf8';

my @feed_uri = @ARGV;
for (@feed_uri) {
    my $feed = XML::Feed->parse(URI->new($_)) or next;

    if ($opts{o} && -d $opts{o}) {
        $file = $opts{o} . "/feed_$i.m4a"; $i++;
    }

    print_and_tts($feed->title, $file);
    sleep 1;
    my @entries = $feed->entries;
    for my $entry (shuffle @entries) {
        my $title = $entry->title;
        $title = decode_utf8($title) unless Encode::is_utf8($title);
        my $description = $striper->parse($entry->summary->body || $entry->content->body || '');
        $striper->eof;

        $description = decode_utf8($description) unless Encode::is_utf8($description);


        my $msg;
        if (index($description, $title) >= 0) {
            $msg = $description;
        } else {
            $msg = $title . "\N{IDEOGRAPHIC FULL STOP}" . $description;
        }

        $msg =~ s/$RE{URI}/ /g;
        # $msg =~ s/[\p{Punct}\p{Space}]{2,}/ /g;
        # $msg =~ s/\s{2,}/\N{IDEOGRAPHIC FULL STOP}/g;
        # $msg =~ s/(\p{Han}) (\p{Han})/$1\N{IDEOGRAPHIC FULL STOP}$2/g;
        $msg =~ s/\p{Space}+\z//;
        $msg =~ s/\A\p{Space}+//;
        next if $msg =~ /\A\p{Space}*\z/;

        if ($opts{o} && -d $opts{o}) {
            $file = $opts{o} . "/feed_$i.m4a"; $i++;
        }
        if ($opts{n}) {
            say "> $msg";
        } else {
            print_and_tts($msg, $file);
        }
    }
}
