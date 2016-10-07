#!/usr/bin/env perl

use v5.18;

my ($fn_in, $fn_out) = @ARGV;
-f $fn_in or die "No input: $fn_in";
-f $fn_out and die "Existing output: $fn_out";

open my $fh_in, "<", $fn_in;
open my $fh_out, ">", $fn_out;

local $/ = "\n";
my $is_header = 0;
my $prev_line = "\n";

while(my $line = <$fh_in>) {
    if ($is_header) {
        if ($line eq "\n") {
            $is_header = 0;
        } elsif ($line =~ /^(From|To): /) {
            $line =~ s/ at /@/gs;
        }
    } else {
        if ($line =~ /^From / && ($prev_line eq "\n")) {
            $is_header = 1;
        }
    }

    if ($is_header) {

    }

    print $fh_out $line;
    $prev_line = $line;
}
