#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Encode qw(encode_utf8 decode_utf8);
use YAML;

my (%lcontext, %rcontext);

while(<>) {
    chomp;
    $_ = decode_utf8($_);
    my @phrase = split /\P{Letter}/, $_;

    for (@phrase) {
        next unless /\A\p{Han}+\z/;

        my @c = split("", $_);

        for my $i (0..$#c) {
            if ($i > 0) {
                $lcontext{$c[$i]}{$c[$i-1]}++;
                if ($i >= 2) {
                    $lcontext{$c[$i-1] . $c[$i]}{$c[$i-2]}++;
                }
                if ($i >= 3) {
                    $lcontext{$c[$i-2] . $c[$i-1] . $c[$i]}{$c[$i-3]}++;
                }
            }
            if ($i < $#c) {
                $rcontext{$c[$i]}{$c[$i+1]}++;

                if ($i+2 <= $#c) {
                    $rcontext{$c[$i] . $c[$i+1]}{$c[$i+2]}++;

                    if ($i+3 <= $#c) {
                        $rcontext{$c[$i] . $c[$i+1] . $c[$i+2]}{$c[$i+3]}++;
                    }
                }
            }
        }
    }
}


my $threshold = 5;
for my $x (uniq((keys %lcontext), (keys %rcontext))) {
    next unless length($x) > 1;
    next unless ($threshold <= (keys %{$lcontext{$x}}) && $threshold <= (keys %{$rcontext{$x}}));
    say encode_utf8($x);
}

