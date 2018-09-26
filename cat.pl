#!/usr/bin/env perl
use strict;
use warnings;

my $READ_SIZE = 2**20;

sub cat {
    my ($fh) = @_;
    my $eof = 0;
    my $buf;
    while (read($fh, $buf, $READ_SIZE)) {
        print $buf;
        $buf = '';
    }
}

if (-p STDIN) {
    cat(\*STDIN)
}
for(@ARGV) {
    open(my $fh, "<", $_) or next;
    cat($fh);
    close($fh);
}
