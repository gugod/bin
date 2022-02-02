#!/usr/bin/env perl
use v5.28;

my %cf;
binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
while(<STDIN>) {
    s/(\p{Punct}|\s|\P{Han})//g;
    $cf{$_}++ for split //;
}
for (keys %cf) {
    print $_ . "\t" . delete($cf{$_}) . "\n";
}
