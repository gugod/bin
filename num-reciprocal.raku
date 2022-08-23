#!/usr/bin/env raku

sub reciprocal ( Int $n, Bool $wantDigits = False ) {
    my %seen := {};
    my $pos = 0;
    my @digits;
    my Int $remainder = 1;

    until %seen{$remainder}:exists {
        %seen{$remainder} = $pos;

        if $wantDigits {
            @digits.push: $remainder div $n;
        }

        $remainder = $remainder % $n * 10;
        $pos++;
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
