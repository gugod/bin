#!/usr/bin/env perl6

my $lines_total = 0;
my $chars_total = 0;
for $*IN.lines -> $line {
    $lines_total += 1;
    $chars_total += $line.chars;

    print($lines_total ~ "\t" ~ $chars_total ~ "\r");
}
print($lines_total ~ "\t" ~ $chars_total ~ "\n");
