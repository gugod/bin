#!/usr/bin/env perl
use v5.36;
use builtin    qw( true );
use List::Util qw( uniq first );

if (@ARGV) {
    solveCryptarithm($_) for @ARGV;
}
else {
    die "Give me some cryptarithm puzzles in \@ARGV\n";
}

sub solveCryptarithm ($cryptExpr) {
    say "# $cryptExpr";
    for my $plainExpr ( decryptarithm($cryptExpr) ) {
        say $plainExpr;
    }
}

sub exclude ( $bag, $throwAways ) {
    my %toThrow = map { $_ => true } @$throwAways;

    [grep { !$toThrow{$_} } @$bag];
}

sub comb ( $re, $str ) { $str =~ m/($re)/g }

sub distinctLetters ($str) { uniq comb qr/[A-Z]/, $str }

sub firstLetters ($str) { comb qr/([A-Z])[A-Z]*/, $str }

sub bindLetter ( $c, $vals, $f ) {
    map { $f->($_) } @$vals;
}

sub plaintextfy ( $cryptext, $digitFromLetter ) {
    join "", map { $digitFromLetter->{$_} // $_ } split //, $cryptext
}

sub decryptarithm (
    $cryptExpr,
    $letters         = [distinctLetters $cryptExpr ],
    $isNonZeroLetter = +{ map { $_ => true } firstLetters $cryptExpr },
    $digitFromLetter = +{},
    $digitAssigned   = +{},
    )
{
    my $unboundLetter = first { !exists $digitFromLetter->{$_} } @$letters;

    unless ( defined($unboundLetter) ) {
        my $plainExpr = plaintextfy( $cryptExpr, $digitFromLetter );
        my $evalExpr  = $plainExpr =~ s/=/==/gr;

        # assume the world is a good place.
        return eval($evalExpr) ? $plainExpr : ();
    }

    my @possibleDigits = grep { not $digitAssigned->{$_} } ( ( $isNonZeroLetter->{$unboundLetter} ? 1 : 0 ) .. 9 );

    map {
        decryptarithm(
            $cryptExpr, $letters, $isNonZeroLetter,
            +{ %$digitFromLetter, $unboundLetter, $_ },
            +{ %$digitAssigned,   $_,             true },
        )
    } @possibleDigits;
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
