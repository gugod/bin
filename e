#!/usr/bin/env perl
use strict;
use warnings;

my $whatever = shift(@ARGV) or die "Cannot edit without an argument.";

my $RE_int  = qr{[1-9][0-9]*};
my $RE_path = qr{.+}u;

my ($path, $line, $column);

if ($whatever =~ m{\A (?:file://)? ($RE_path) (?: : ($RE_int) : ($RE_int))? \z}x) {
    ($path, $line, $column) = ($1, $2, $3);
}

if ($path) {
    my $pos = ($line && $column) ? "+$line:$column" : $line ? "+$line" : "";

    exec "emacsclient", "-n", $pos ? $pos : (), $path;
}

die "Don't know how to deal with $whatever\n";
