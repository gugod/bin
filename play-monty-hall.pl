#!/usr/bin/env perl
use v5.38;
use feature 'class';
no warnings 'experimental::class';

class Game {
    field $doors :param;
    field $winningDoor = 1 + int rand($doors);

    method doors { $doors }
    method winningDoor { $winningDoor }

    method loosingDoors {
        grep { $_ != $winningDoor } (1..$doors);
    }
};

class FirstChoicePlayer {
    field $doors :param;
    field $firstChoice = 1 + int rand($doors);
    field @loosingDoors;

    method doors { $doors }
    method addLoosingDoors ($n) { push @loosingDoors, $n }
    method loosingDoors () { @loosingDoors }
    method firstChoice () { $firstChoice }
    method finalChoice () { $firstChoice }
};

class ChangeChoicePlayer :isa(FirstChoicePlayer) {
    method finalChoice () {
        my %isLoosing = map { $_ => 1 } $self->loosingDoors();
        my @choices = grep { $_ != $self->firstChoice() } grep { ! $isLoosing{$_} } 1..$self->doors();

        die "Illegal state" if @choices != 1;
        return $choices[0];
    }
};

class GameMaster {
    field $doors :param;
    method playWith ($player) {
        die "No player ?" unless defined $player;

        my $game = Game->new( doors => $doors );

        my %untold = map { $_ => 1 } ($game->winningDoor, $player->firstChoice);
        while ((keys %untold) == 1) {
            my $door = 1 + int rand($doors);
            $untold{$door} = 1;
        }
        my @revealLoosingDoors = grep { ! $untold{$_} } (1..$doors);

        for my $door (@revealLoosingDoors) {
            $player->addLoosingDoors($door)
        }

        my $finalChoice = $player->finalChoice();

        return $finalChoice == $game->winningDoor;
    }
};

sub playOneRound($playerClass) {
    my $doors = 3;
    my $gm = GameMaster->new( doors => $doors );
    my $player = $playerClass->new( doors => $doors );
    return $gm->playWith( $player );
}

sub play ($rounds, $playerClass) {
    my $wins = 0;
    for (1 .. $rounds) {
        my $win = playOneRound($playerClass);
        $wins++ if $win;
    }
    return $wins;
}

sub sim ($rounds) {
    for my $playerClass ("FirstChoicePlayer", "ChangeChoicePlayer") {
        my $wins = play($rounds, $playerClass);
        my $pWin = $wins / $rounds;
        say "$playerClass wins $wins / $rounds. p(win) = $pWin";
    }
}

sim(shift // 1000);
