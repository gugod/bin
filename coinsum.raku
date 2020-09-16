#!/usr/bin/env raku

sub gen_coin_sum(Int $sum, @coins) {
    my @stack = @coins.map(-> $k { %( sum => $k, coins => ($k)) });

    while @stack.elems > 0 {
        my %x = @stack.pop();

        if %x<sum> == $sum {
            # Found!
            say "$sum = [+] " ~ %x<coins>;
        }
        elsif %x<sum> < $sum {
            for @coins -> $k {
                my $s = %x<sum> + $k;
                if $s <= $sum {
                    my @coins = %x<coins>.flat;
                    if @coins[*-1] >= $k {
                        @coins.push($k);
                        @stack.push(%( sum => $s, coins => @coins ));
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
