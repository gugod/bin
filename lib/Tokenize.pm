package Tokenize;
use v5.14;
use strict;
use Unicode::UCD qw(charscript);

sub normalize_whitespace {
    local $_ = $_[0];
    s/[\t ]+/ /g;
    s/\A\s+//;
    s/\s+\z//;
    return $_;
}

sub remove_spaces {
    return grep { ! /\A\s*\z/u } @_;
}

sub by_script($) {
    my $str = normalize_whitespace($_[0]);
    my @tokens;
    my @chars = grep { defined($_) } split "", $str;
    return () unless @chars;

    my $t = shift(@chars);
    my $s = charscript(ord($t));
    while(my $char = shift @chars) {
        my $_s = charscript(ord($char));
        if ($_s eq $s) {
            $t .= $char;
        }
        else {
            push @tokens, $t;
            $s = $_s;
            $t = $char;
        }
    }
    push @tokens, $t;
    return remove_spaces map { $_ = normalize_whitespace($_) } @tokens;
}

sub standard {
    map { /\p{Ideographic}/ ? (split "") : $_ } by_script($_[0]);
}

sub ngram($) {
    my @t;
    my $s = $_[0];
    my $l = length($s);
    while($l > 1) {
        for (2..$l-1) {
            push @t, substr($s, 0, $_);
        }
        $s = substr($s, 1);
        $l = length($s);
    }
    return @t;
}

sub shingle($@) {
    my ($size, @t) = @_;
    my @x;
    for (0..$#t-$size) {
        push @x, join " ", @t[$_ .. $_+$size-1];
    }
    return @x;
}

sub by_script_than_ngram($) {
    my @token = by_script(lc($_[0]));
    return @token, map { ngram( $_ ) } @token ;
}

sub by_script_with_ngram_and_shingle($) {
    my $str = lc($_[0]);
    my @token = by_script($str);
    my @shingle;
    for (0..$#token-1) {
        push @shingle, $token[$_] . " " . $token[$_+1];
    }

    return @shingle, @token, map { ngram($_) } @token;
}

sub standard_than_shingle2 {
    my @tokens = standard($_[0]);
    my @shingles = shingle(2, @tokens);
    return (@tokens, @shingles);
}

1;
