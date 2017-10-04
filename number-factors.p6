#!/usr/bin/env perl6

my $number = @*ARGS[0];

my @factors;
for 1..floor(sqrt($number)) -> $x {
    my $y = $number / $x;
    if floor($y) == $y {
        @factors.push($x);
        @factors.push($y);
    }
}

@factors.sort.join(" ").say;
