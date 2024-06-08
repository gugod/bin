use v5.38;
use feature 'class';
no warnings 'experimental::class';

class Game {
    my $doors = 3;
    field $winningDoor = 1 + int rand($doors);
    field $chosenDoor;

    method winningDoor { $winningDoor }

    method chosenDoor($v) {
        $chosenDoor = $v if defined($v)
    }

    method loosingDoors {
        die "Missing: chosenDoor" unless defined($chosenDoor);
        my %untold = map { $_ => 1 } ($winningDoor, $chosenDoor);
        while ((keys %untold) == 1) {
            my $door = 1 + int rand($doors);
            $untold{$door} = 1;
        }
        grep { ! $untold{$_} } (1..$doors);
    }

    method win {
        die "Missing: chosenDoor" unless defined($chosenDoor);
        $chosenDoor == $winningDoor
    }
}

class FirstChoicePlayer {
    field $doors = 3;
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
}

sub sim_one_round($playerClass) {
    my $player = $playerClass->new;
    my $game = Game->new;

    $game->chosenDoor( $player->firstChoice );

    for my $door ($game->loosingDoors()) {
        $player->addLoosingDoors($door)
    }

    $game->chosenDoor( $player->finalChoice() );

    $game;
}

sub sim ($roundsToPlay, $playerClass) {
    my $wins = 0;
    for (1 .. $roundsToPlay) {
        my $game = sim_one_round($playerClass);
        $wins++ if $game->win();
    }
    return $wins;
}

my $rounds = 1000000;
for my $playerClass ("ChangeChoicePlayer", "FirstChoicePlayer") {
    my $wins = sim($rounds, $playerClass);
    say "$playerClass wins $wins / $rounds";
}
