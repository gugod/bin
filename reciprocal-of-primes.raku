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

    return ( @digits, %seen{$remainder}, $pos -  %seen{$remainder});
}

sub MAIN (Int :$from = 2, Int :$until) {
    for ($from..($until || Inf)).hyper.grep(&is-prime) -> $p {
        my (Mu, $repeat-pos, $repeat-length) =  reciprocal( $p );
        say join "\t", $p, $repeat-pos, $repeat-length;
    }
}
