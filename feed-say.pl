#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;

use Regexp::Common qw/URI/;
use HTML::Strip;
use URI;
use XML::Feed;
use Getopt::Long;

sub print_and_tts {
    my ($str, $file) = @_;
    say "$str";
    say "----";

    my $voice;
    if ($str =~ /^\p{ASCII}+$/) {
        $voice = random("Daniel", "Jill");
    } elsif ($str =~ /(\p{Hiragana}|\p{Katakana})/) {
        $voice = "Kyoko";
    } elsif ($str =~ /\p{Han}/) {
        $voice = "Ya-Ling";
    }
    
    system("say", ($voice ? ('-v', $voice) : ()), ($file ? ('-o', $file): ()), $str);
}

my %opts;
GetOptions(
    \%opts,
    "o",
);
my @feeds = map { chomp; XML::Feed->parse(URI->new($_)) } @ARGV;

my $striper = HTML::Strip->new;

my $i = "0000";
my $file;
binmode STDOUT, ':utf8';
for my $feed (@feeds) {
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
        $msg =~ s/\p{Space}+\z//;
        $msg =~ s/\A\p{Space}+//;
        next if $msg =~ /\A\p{Space}*\z/;

        if ($opts{o} && -d $opts{o}) {
            $file = $opts{o} . "/feed_$i.m4a"; $i++;
        }
        print_and_tts($msg, $file);
    }
}
