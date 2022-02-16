#!/usr/bin/env raku

sub MAIN (Int :$from = 5, Int :$until) {
    my @sexy-prime-leads = ($from ... ($until // Inf)).lazy.grep(-> $n {
        $n.is-prime and ($n+6).is-prime
    });

    for @sexy-prime-leads -> $n {
        say $n ~ "\t" ~ ($n+6);
    }
}
