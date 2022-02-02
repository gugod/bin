#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;

use JSON::PP;
use Encode qw(decode_utf8 encode_utf8);

sub build_lookup_table {
    my ($stash) = @_;
    my (%seen, %rev_seen);
    my $id = 1;
    for my $str (@{delete $stash->{_input}}) {
        unless (exists $seen{$str}) {
            $seen{$str} = $id;
            $rev_seen{$id} = $str;
            $id += 1;
        }
    }

    $stash->{lookup}{id} = \%seen;
    $stash->{lookup}{hanseq} = \%rev_seen;
}

sub grok_struct {
    my ($stash, $text) = @_;

    my $head = substr($text, 0, 1);
    my $tail = substr($text, -1, 1);
    $stash->{head_tail_gram}{$head . ".+" . $tail} ++;

    if (length($text) > 3) {
        for my $l (2 ... length($text)) {
            $head = substr($text, 0, $l);
            $tail = substr($text, -$l, $l);
            $stash->{prefix}{$head}++;
            $stash->{suffix}{$tail}++;
        }
    }
}

sub build_char_index {
    my ($stash) = @_;

    my %idx;
    for my $hanseq (keys %{$stash->{lookup}{id}}) {
        my $id = $stash->{lookup}{id}{$hanseq};
        my $len = length($hanseq);
        for my $pos (0 .. $len-1) {
            my $char = substr($hanseq, $pos, 1);
            $idx{$char} //= {
                in_hanseq => {},
            };
            push @{ $idx{$char}{in_hanseq}{$id} }, $pos;
        }
    }

    $stash->{char_index} = \%idx;
}

sub store_struct {
    my ($stash) = @_;

    for my $struct_name (qw( head_tail_gram prefix suffix )) {
        open my $fh, ">:utf8", "$ENV{HOME}/var/grok/han-sequence-struct--${struct_name}.tsv";
        for my $k (grep { $stash->{$struct_name}{$_} > 2 } keys %{$stash->{$struct_name}}) {
            print $fh "$k\t" . $stash->{$struct_name}{$k} . "\n";
        }
        close($fh);
    }
}

my %stash;
while(<>) {
    chomp;
    my $s = decode_utf8($_);
    my @seq = $s =~ /(\p{Han}+)/g;
    for (grep { length($_) > 2 } @seq) {
        push @{$stash->{_input}}, $_;
    }
}

build_lookup_table(\%stash);
build_char_index(\%stash);
grok_struct(\%stash);
store_struct(\%stash);
