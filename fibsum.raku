#!/usr/bin/env raku

my @fib = 1, 2, { $^a + $^b } ... *;

sub fibsum(Int $n) {
    my @subfib = @fib[0 ... @fib.first({ $^fib > $n }, :k)-1];
    say " ... subfib = " ~ @subfib;
    return sumsearch($n, @subfib);
}

sub sumsearch (Int $n, @nums) {
    my @solutions = [];

    if $n == 0 {
        @solutions.push([]);
        return @solutions;
    }

    if @nums.elems == 0 || $n < 0 {
        return @solutions;
    }

    my $firstNum = @nums.pop();
    my @s1 = sumsearch($n, @nums);
    my @s2 = sumsearch($n - $firstNum, @nums).map({ $_.prepend($firstNum) });
    @nums.push($firstNum);

    @solutions.append(@s1);
    @solutions.append(@s2);

    return @solutions;
}

sub MAIN(Int $n) {
    my @solutions = fibsum($n);
    say "|fibsum($n)| = " ~ @solutions.elems;
    say "\n$n";
    for @solutions -> $s {
        say "    = " ~ @$s.join(" + ");
    }
}
