#!/usr/bin/env raku

my @cards = (['♠', '♣', '♡', '♢'] X (1...10, 'J', 'Q', 'K')).pick(*);

while @cards.elems > 0 {
    say "Hit <RET> to draw next card...";
    $*IN.get;

    say "\n" ~ @cards.shift().join(" ") ~ "\n";
}

say "No more cards";
