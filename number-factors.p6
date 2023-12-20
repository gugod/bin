#!/usr/bin/env perl6

sub factorsOf (Int $number) {
    my Int @factors;
    for 1..floor(sqrt($number)) -> $x {
        my $y = $number / $x;
        if floor($y) == $y {
            @factors.push($x.Int());
            @factors.push($y.Int());
        }
    }

    return @factors.sort
}

sub primeFactorsOf(Int $number) {
    factorsOf($number).grep(&is-prime)
}

sub MAIN ($number, Bool :$prime = False) {
    my $f = $prime ?? &primeFactorsOf !! &factorsOf;
    $f($number).join(" ").say()
}
