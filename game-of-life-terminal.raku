#!/usr/bin/env raku
#
# A naive Game of Life in Terminal.
#   Hit 'b' or '!' to restart.
#   Hit 'q' or Ctrl-C to end the game.
#   Hit 'p' to pause
#   When paused, hit <space> to advance to next generation.
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

    has Str $.cell is required;
    has Int $.cell-width = 1;

    has $!T;
    has @!lifes;
    has @!neighbours;
    has Int @!changes;

    has Int $!cols;
    has Int $!rows;

    submethod TWEAK {
        $!T = Terminal::Print.new();
        $!cols = ($!T.columns / $!cell-width).floor;
        $!rows = $!T.rows;
    }

    method paint {
        my @char = (" ", $!cell);
        @!changes.map({
            $!T.print-cell($^b * $!cell-width, $^a, @char[$^c]);
        });
        @!changes = ();
        return self;
    }

    method bang {
        @!lifes = (^$!rows).map({[ (^$!cols).map({ 0 }) ]});
        @!neighbours = (^$!rows).map({[ (^$!cols).map({ 0 }) ]});
        @!changes = ();

        (^($!rows * $!cols / 7)).map({
            my $y = (^$!rows).pick;
            my $x = (^$!cols).pick;
            if @!lifes[$y][$x] == 0 {
                @!lifes[$y][$x] = 1;
                @!changes.push($y, $x, 1);
            }
        });

        return self.commit;
    }

    method neighbours($y, $x) {
        ((-1,-1), (-1,0), (-1,1), (0,-1), (0,1), (1,-1), (1,0), (1,1)).map(
            { $_[0] + $y, $_[1] + $x }
        ).grep(
            { 0 <= $_[0] < $!rows && 0 <= $_[1] < $!cols }
        )
    }

    method notify-neighbours($y, $x, $v) {
        my $d = $v == 0 ?? -1 !! 1;
        for self.neighbours($y, $x) {
            my ($y, $x) = $_[0, 1];
            @!neighbours[$y][$x] += $d;
        }
    }

    method commit {
        @!changes.map({
            @!lifes[$^a][$^b] = $^c;
            self.notify-neighbours($^a, $^b, $^c);
        });
        return self;
    }

    method nextgen {
        for (^$!rows) X (^$!cols) {
            my ($y, $x) = $_;

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

        return self.commit;
    }

    method spawn-random-life {
        my $lifes = 0;
        while $lifes == 0 {
            my $y = (^$!rows).pick;
            my $x = (^$!cols).pick;

            unless @!lifes[$y][$x] == 1 {
                @!changes.push($y, $x, 1);
                $lifes++;
            }
        }
        return self.commit;
    }

    method run {
        class Tick { }
        my $in-supply = raw-input-supply;
        my $timer     = Supply.interval(.1).map: { Tick };
        my $supplies  = Supply.merge($in-supply, $timer);
        my $paused = False;

        $!T.initialize-screen;
        self.bang;
        react {
            whenever $supplies -> $_ {
                when Tick          {
                    self.paint;
                    self.nextgen unless $paused;
                }
                when 'p'           {
                    $paused = !$paused;
                }
                when ' '           {
                    self.nextgen if $paused
                }
                when 'q' | chr(3)  { done               }
                when 'b' | '!'     {
                    $!T.clear-screen;
                    self.bang;
                }
                when 'a' {
                    self.spawn-random-life;
                }
            }
        }
        $!T.shutdown-screen;
    }
}

sub MAIN( Str :$cell = "█", Int :$cell-width ) {

    my $c;
    if my $match = $cell.match(/^\\c\[(.+)\]$/) {
        $c = uniparse( $match[0].Str ) || "█";
    } else {
        $c = $cell.substr(0,1);
    }

    my $w = 1;
    if $cell-width.defined {
        $w = $cell-width;
    } else {
        # Extremely poor wcswidth() here.
        $w = ($c.ord >= 0x1100 ?? 2 !! 1);
    }

    my $game = GameOfLife.new( cell => $c, cell-width => $w );
    $game.run();
}
