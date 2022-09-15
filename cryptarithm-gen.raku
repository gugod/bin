#!/usr/bin/env raku

sub cryptarithm-gen (@nums, @words) {
    my Set $words = @words.Set;
    my @digits = @nums.map({ .comb.Slip }).unique;

    my sub gen (%letter-from-digit) {
        return if @nums.first({
            .comb.map({ %letter-from-digit{$_} }).Array.&{
                .all && .join() ∉ $words
            }});

        my $d = @digits.first({ %letter-from-digit{$_}:!exists });

        my @solutions;

        unless $d.defined {
            @solutions.push( %letter-from-digit );
            return @solutions;
        }

        for (("A".."Z") (-) %letter-from-digit.values).keys.sort -> $c {
            my @s = gen(%( %letter-from-digit, $d => $c ));
            @solutions.append(@s) if @s.elems > 0;
        }

        return @solutions.grep(&defined);
    }

    gen(%());
}

sub print-solution (@nums, %letter-from-digit) {
    say "\t" ~ @nums.map({ $_ ~ " = " ~ .comb.map({ %letter-from-digit{$_} }).join }).join(", ");
}

sub gen-cryptarithm-then-print ($expr, @words) {
    my @nums = $expr.comb(/<[0..9]>+/);
    my @solutions = cryptarithm-gen(@nums, @words);

    if @solutions.any {
        say "# Cryptarithm for: $expr";
        for @solutions -> $s {
            print-solution(@nums, $s);
        }
    } else {
        say "# Cryptarithm for: $expr\n    Not found.";
    }
}

sub MAIN (Bool :$primes = False, Str :$expr = "") {
    my @words = "/usr/share/dict/words".IO.lines.map(&uc).grep({ .chars < 11 || .comb.unique.elems < 11 });

    if $primes {
        my @primes =(1000..99999).grep(&is-prime);
        for @primes.combinations(2) -> ($n1, $n2) {
            my $n = $n1 + $n2;
            gen-cryptarithm-then-print("$n1 + $n2 = $n", @words);
        }
    } elsif $expr ne "" {
        gen-cryptarithm-then-print($expr, @words);
    } else {
        say "What do you want me to do ?";
    }
}
