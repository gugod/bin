#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;

use Regexp::Common qw/URI/;
use HTML::Strip;
use URI;
use XML::Feed;
use Getopt::Long;

sub pick {
    $_[ rand(@_) ]
}

sub print_and_tts {
    my ($str, $file) = @_;
    my $voice;
    if ($str =~ /^\p{ASCII}+$/) {
        $voice = pick("Daniel", "Samantha");
    } elsif ($str =~ /(\p{Hiragana}|\p{Katakana})/) {
        $voice = "Kyoko";
    } elsif ($str =~ /\p{Han}/) {
        $voice = "Mei-Jia";
    }

    say (($voice ? "[$voice] ": "") . $str . "\n----");

    my @cmd = ("say", ($voice ? ('-v', $voice) : ()), ($file ? ('-o', $file): ()), $str);
    (system(@cmd) == 0) or die "ABORT\n";
}

my %opts;
GetOptions(
    \%opts,
    "o",
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
    for my $entry ($feed->entries) {
        my $title = $entry->title;
        my $description = $striper->parse($entry->summary->body || $entry->content->body || '');
        $striper->eof;

        my $msg;
        if (index($description, $title) >= 0) {
            $msg = $description;
        } else {
            $msg = $title . "\N{IDEOGRAPHIC FULL STOP}" . $description;
        }

        $msg =~ s/$RE{URI}/ /g;
        $msg =~ s/[\p{Punct}\p{Space}]{2,}/ /g;
        $msg =~ s/\s{2,}/\N{IDEOGRAPHIC FULL STOP}/g;
        $msg =~ s/(\p{Han}) (\p{Han})/$1\N{IDEOGRAPHIC FULL STOP}$2/g;
        $msg =~ s/\p{Space}+\z//;
        $msg =~ s/\A\p{Space}+//;
        next if $msg =~ /\A\p{Space}*\z/;

        if ($opts{o} && -d $opts{o}) {
            $file = $opts{o} . "/feed_$i.m4a"; $i++;
        }
        print_and_tts($msg, $file);
    }
}
