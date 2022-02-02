#!/usr/bin/env raku

sub MAIN (Int :$from = 5) {
    my $p = ($from ... Inf).first(&is-prime);
    my @sexy_prime_lead = $p, {
        my $n = $^a + 2;
        $n += 2 until $n.is-prime() and ($n+6).is-prime();
        $n
    } ... Inf;

    for @sexy_prime_lead -> $n {
        say $n ~ "\t" ~ ($n+6);
    }
}
