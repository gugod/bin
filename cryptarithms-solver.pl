#!/usr/bin/env perl
use v5.36;
use builtin qw( true );
use List::Util qw( uniq );

if (@ARGV) {
    solveCryptarithm($_) for @ARGV;
}
else {
    while (my $expr = <>) {
        chomp($expr);
        solveCryptarithm($expr);
    }
}
exit();

sub solveCryptarithm ($cryptExpr) {
    say "# $cryptExpr";
    for my $plainExpr ( decryptarithm($cryptExpr) ) {
        say $plainExpr;
    }
}

sub plaintextfy ($cryptext, $digitFromLetter) {
    my $plaintext = $cryptext;
    for my $c (keys %$digitFromLetter) {
        my $d = $digitFromLetter->{$c};
        $plaintext =~ s/$c/$d/g;
    }
    return $plaintext;
}

sub exclude($bag, $throwAways) {
    my %toThrow = map { $_ => true } @$throwAways;

    [ grep { ! $toThrow{$_} } @$bag ]
}


sub comb ($re, $str) { $str =~ m/($re)/g }

sub distinctLetters ($str) { uniq comb qr/[A-Z]/, $str }

sub firstLetters ($str) { comb qr/([A-Z])[A-Z]*/, $str }

sub ArrayRef (@args) { [ @args ] }

sub HashSet (@args) { +{ map { $_ => true } @args } }

sub decryptarithm (
    $cryptExpr,
    $letters          = ArrayRef( distinctLetters $cryptExpr ),
    $isNonZeroLetter  = HashSet( firstLetters $cryptExpr ),
    $digitFromLetter  = {},
    $digitsUnassigned = [0..9]
) {
    my @unboundLetters = grep { ! exists $digitFromLetter->{$_} } @$letters;

    if (@unboundLetters == 0) {
        my $plainExpr = plaintextfy($cryptExpr, $digitFromLetter);
        my $evalExpr = $plainExpr =~ s/=/==/gr;

        # assume the world is a good place.
        return eval($evalExpr) ? $plainExpr : ();
    }

    my $c = $unboundLetters[0];
    my $vals = $isNonZeroLetter->{$c} ? exclude($digitsUnassigned, [0]) : $digitsUnassigned;
    map {
        my $d = $_;
        decryptarithm(
            $cryptExpr,
            $letters,
            $isNonZeroLetter,
            { %$digitFromLetter, $c, $d },
            exclude( $digitsUnassigned, [ $d ] ),
        )
    } @$vals;
}

__DATA__
SO + SO = TOO
TOO - SO = SO
XY * YZ = XYZ
COCA + COLA = OASIS
NO + GUN + NO = HUNT
THREE + THREE + TWO + TWO + ONE = ELEVEN
CROSS + ROADS = DANGER
MEMO + FROM = HOMER
FORTY + TEN + TEN = SIXTY
SEND + MORE = MONEY
NUMBER + NUMBER = PUZZLE
