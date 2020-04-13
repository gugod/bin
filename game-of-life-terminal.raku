#!/usr/bin/env raku
#
# A naive Game of Life in Terminal. Ctrl-C to exit.
#
# In memory of John Conway.
#
# LICENSE: CC0
#   To the extent possible under law, Kang-min Liu has waived all
#   copyright and related or neighboring rights to
#   game-of-life-terminal.raku. This work is published from: Taiwan.

use v6;

class GameOfLife {
    use Terminal::Print;

    has $!T;
    has @!lifes;
    has @!changes;

    has $!cols;
    has $!rows;

    submethod BUILD {
        $!T = Terminal::Print.new();

        $!cols = $!T.columns;
        $!rows = $!T.rows;
        @!lifes = (^$!rows).map({[ (^$!cols).map({ 0 }) ]});
    }

    method paint {
        my @char = (" ", "█");
        @!changes.map({
            $!T.print-cell($^b, $^a, @char[$^c]);
        });

        return self;
    }

    method bang {
        (^($!rows * $!cols / 7)).map({
            my $y = (^$!rows).pick;
            my $x = (^$!cols).pick;
            if @!lifes[$y][$x] == 0 {
                @!lifes[$y][$x] = 1;
                @!changes.push($y, $x, 1);
            }
        });

        return self;
    }

    method nextgen {
        sub count-neighbours($y, $x) {
            my $n = 0 - @!lifes[$y][$x];
            for ($y-1, $y, $y+1).grep({ 0 <= $_ < $!rows }) -> $y {
                for ($x-1, $x, $x+1).grep({ 0 <= $_ < $!cols }) -> $x {
                    $n += @!lifes[$y][$x];
                }
            }
            return $n;
        }

        @!changes = ();
        for ^$!rows -> $y {
            for ^$!cols -> $x {
                my $n = count-neighbours($y, $x);
                if @!lifes[$y][$x] == 0 {
                    if $n == 3 {
                        @!changes.push($y, $x, 1);
                    }
                } else {
                    unless 2 <= $n <= 3 {
                        @!changes.push($y, $x, 0);
                    }
                }
            }
        }

        @!changes.map({
            @!lifes[$^a][$^b] = $^c;
        });

        return self;
    }


    method run {
        $!T.initialize-screen;

        loop {
            self.paint.nextgen;
        }

        $!T.shutdown-screen;
    }
}

sub MAIN() {
    GameOfLife.new().bang().run();
}
