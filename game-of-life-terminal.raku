#!/usr/bin/env raku
#
# A naive Game of Life in Terminal. Hit 'q' or Ctrl-C to end the game.
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
    use Terminal::Print::RawInput;

    has $!T;
    has @!lifes;
    has @!neighbours;
    has @!changes;

    has $!cols;
    has $!rows;

    submethod BUILD {
        $!T = Terminal::Print.new();
        $!cols = $!T.columns;
        $!rows = $!T.rows;
    }

    method paint {
        my @char = (" ", "█");
        @!changes.map({
            $!T.print-cell($^b, $^a, @char[$^c]);
        });

        return self;
    }

    method bang {
        @!lifes = (^$!rows).map({[ (^$!cols).map({ 0 }) ]});
        @!neighbours = (^$!rows).map({[ (^$!cols).map({ 0 }) ]});

        (^($!rows * $!cols / 7)).map({
            my $y = (^$!rows).pick;
            my $x = (^$!cols).pick;
            if @!lifes[$y][$x] == 0 {
                @!lifes[$y][$x] = 1;
                @!changes.push($y, $x, 1);
                self.notify-neighbours($y, $x, 1);
            }
        });

        return self;
    }

    method neighbours($y, $x) {
        my @r = ($y-1, $y, $y+1).grep({ 0 <= $_ < $!rows });
        my @c = ($x-1, $x, $x+1).grep({ 0 <= $_ < $!cols });
        return (@r X @c).grep({ ($_[0] != $y || $_[1] != $x) })
    }

    method notify-neighbours($y, $x, $v) {
        my $d = $v == 0 ?? -1 !! 1;
        for self.neighbours($y, $x) {
            my ($y, $x) = $_[0, 1];
            @!neighbours[$y][$x] += $d;
        }
    }

    method nextgen {
        @!changes = ();
        for ^$!rows -> $y {
            for ^$!cols -> $x {
                my $n = @!neighbours[$y][$x];
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
            self.notify-neighbours($^a, $^b, $^c);
        });

        return self;
    }


    method run {
        class Tick { }
        my $in-supply = raw-input-supply;
        my $timer     = Supply.interval(.1).map: { Tick };
        my $supplies  = Supply.merge($in-supply, $timer);

        $!T.initialize-screen;
        self.bang;
        react {
            whenever $supplies -> $_ {
                when Tick          { self.paint.nextgen }
                # 'q' or Ctrl-C to quit.
                when 'q' | chr(3)  { done               }
                when 'b' | '!'     {
                    self.bang;
                    $!T.clear-screen;
                }
            }
        }
        $!T.shutdown-screen;
    }
}

sub MAIN() {
    GameOfLife.new().bang().run();
}
