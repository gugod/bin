#!/usr/bin/env perl
use v5.18;
use warnings;
use feature 'signatures';

use Encode ("encode_utf8");
use String::Trim ("trim");
use Text::Util::Chinese ("sentence_iterator", "phrase_iterator", "looks_like_simplified_chinese");

my $stdin_iter = do {
    my $fh = \*STDIN;
    binmode $fh, ":utf8";
    sub { <$fh> };
};

my $iter = Text::Util::Chinese::grep_iterator(
    phrase_iterator($stdin_iter),
    sub { (length($_) > 1) && /\p{Han}/ && (!/\p{Script:Hiragana}/) && (! /\p{Script:Katakana}/) && (! looks_like_simplified_chinese($_)) }
);

Text::Util::Chinese::exhaust(
    $iter,
    sub ($it) {
        $it = trim($it);
        say encode_utf8($it);
    }
);
