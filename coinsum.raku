#!/usr/bin/env raku

sub gen_coin_sum(Int $sum, @coins) {
    my @stack = @coins.map(-> $k { %( sum => $k, coins => %($k, 1), _last => $k ) });

    while @stack.elems > 0 {
        my %x = @stack.pop();

        if %x<sum> == $sum {
            # Found!
            say "$sum = " ~ (%x<coins>.sort({ .key.Int }).reverse.map(-> $p { $p.key ~ "×" ~ $p.value })).join(" + ");
        }
        elsif %x<sum> < $sum {
            for @coins -> $k {
                my $s = %x<sum> + $k;
                if $s <= $sum {
                    my %coins = %x<coins>;
                    if %x<_last> >= $k {
                        %coins{$k} += 1;
                        @stack.push(%( sum => $s, coins => %coins, _last => $k ));
                    }
                }
            }
        }
    }
}

sub MAIN (Int $sum, Str $coins) {
    my @coins = $coins.split(",").map({ .Int }).sort;
    gen_coin_sum($sum, @coins);
}
