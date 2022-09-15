#!/usr/bin/env raku

sub reciprocal ( Int $n, Bool $want-digits = False ) {
    my %seen := {};
    my $pos = 0;
    my @digits;
    my Int $remainder = 1;

    until %seen{$remainder}:exists {
        %seen{$remainder} = $pos++;

        @digits.push( $remainder div $n ) if $want-digits;

        $remainder = $remainder % $n * 10;
    }

    return ( @digits, %seen{$remainder}, $pos );
}

sub MAIN (Int :$from = 2) {
    for ($from..*).grep(&is-prime) -> $p {
        my (Mu, $repeat-from, $repeat-at) =  reciprocal( $p );
        say $p ~ "\t" ~ $repeat-at ~ "\t" ~ ($repeat-at - $repeat-from);
    }
}
