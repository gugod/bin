#!/usr/bin/env perl
use v5.32;

my ($from, $until) = @ARGV[0,1];
while(defined(my $num = <STDIN>)) {
    if ($from <= $num < $until) {
        print $num;
    }
}
