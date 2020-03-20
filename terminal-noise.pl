#!/usr/bin/env perl
## dependencies: Term::Size Term::ANSIScreen
use v5.28;
use integer;
use Term::Size ();
use Term::ANSIScreen qw(:color :cursor);

my ($cols, $rows);
local $SIG{'WINCH'} = sub {
    ($cols, $rows) = Term::Size::chars();
};
kill 'WINCH', $$;

print(
    locate(1+rand($rows),1+rand($cols)),
    colored(
        chr(32+rand(127-32)),
        qw(black red green yellow blue magenta cyan white)[rand(8)])
) while 1;
