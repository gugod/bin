# print the series of primes that are the partial sums of first n primes.

sub MAIN($limit = Inf) {
    my @primes = (2..∞).grep(&is-prime);
    my @partial-sum-primes = (0..Inf).map({ @primes[0..$_].sum() }).grep(&is-prime);

    .say for @partial-sum-primes.head($limit);
}
