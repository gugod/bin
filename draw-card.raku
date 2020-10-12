#!/usr/bin/env raku

my @cards = (['♠', '♣', '♡', '♢'] X (1...10, 'J', 'Q', 'K')).pick(*);

say "Hit <RET> to draw next card...";
while @cards.elems > 0 {
    $*IN.get;
    say @cards.shift().join(" ");
}

say "No more cards";
