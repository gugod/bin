#!/usr/bin/env perl6

my $max = -Inf;

for $*IN.lines -> $n {
    if ($n > $max) {
        say $n;
        $max = $n;
    }
}
