#!/usr/bin/env perl6
#
# Calculate the numerical average of input numbers.
#

use v6;
my @a = $*IN.slurp.split(/\s+/).grep({ $_ ne "" });

my $min = [min] @a;
my $max = [max] @a;
my $sum = [+] @a;
my $mean = $sum / @a;

say "Sum: $sum";
say "Mean: $mean";
say "Max: $max";
say "Min: $min";

