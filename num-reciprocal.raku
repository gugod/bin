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

sub MAIN ( Int $n, Bool :$show = False ) {
    my ($digits, $repeat-from, $repeat-at) =  reciprocal( $n, $show );

    say "1/$n start to repeat at the " ~ ($repeat-at) ~ "-th digits after the decimal point,";
    say "The length of repeating digits is " ~ ($repeat-at - $repeat-from) ~ ".";

    if $show {
        say $digits[0] ~ "." ~ $digits[1..*].join("") ~ "...";
    }
}
