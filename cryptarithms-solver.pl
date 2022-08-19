#!/usr/bin/env perl
use v5.36;
use builtin    qw( true );
use List::Util qw( uniq first );

if (@ARGV) {
    solveCryptarithm($_) for @ARGV;
}
else {
    while ( my $expr = <> ) {
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

sub exclude ( $bag, $throwAways ) {
    my %toThrow = map { $_ => true } @$throwAways;

    [grep { !$toThrow{$_} } @$bag];
}

sub extend ( $hashref, $k, $v ) {
    +{ %$hashref, $k, $v }
}

sub comb ( $re, $str ) { $str =~ m/($re)/g }

sub distinctLetters ($str) { uniq comb qr/[A-Z]/, $str }

sub firstLetters ($str) { comb qr/([A-Z])[A-Z]*/, $str }

sub ArrayRef (@args) { [@args] }

sub SetHashRef (@args) {
    +{ map { $_ => true } @args }
}

sub bindLetter ( $c, $vals, $f ) {
    map { $f->($_) } @$vals;
}

sub plaintextfy ( $cryptext, $digitFromLetter ) {
    my $plaintext = $cryptext;
    for my $c ( keys %$digitFromLetter ) {
        my $d = $digitFromLetter->{$c};
        $plaintext =~ s/$c/$d/g;
    }
    return $plaintext;
}

sub decryptarithm (
    $cryptExpr,
    $letters          = ArrayRef( distinctLetters $cryptExpr ),
    $isNonZeroLetter  = SetHashRef( firstLetters $cryptExpr ),
    $digitFromLetter  = {},
    $digitsUnassigned = [0 .. 9]
    )
{
    my $unboundLetter = first { !exists $digitFromLetter->{$_} } @$letters;

    unless ( defined($unboundLetter) ) {
        my $plainExpr = plaintextfy( $cryptExpr, $digitFromLetter );
        my $evalExpr  = $plainExpr =~ s/=/==/gr;

        # assume the world is a good place.
        return eval($evalExpr) ? $plainExpr : ();
    }

    my $possibleDigits = $isNonZeroLetter->{$unboundLetter} ? exclude( $digitsUnassigned, [0] ) : $digitsUnassigned;

    bindLetter $unboundLetter, $possibleDigits, sub ($d) {
        decryptarithm(
            $cryptExpr, $letters, $isNonZeroLetter,
            extend( $digitFromLetter, $unboundLetter, $d ),
            exclude( $digitsUnassigned, [$d] ),
        )
    }
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
