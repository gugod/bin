#!/usr/bin/env perl
use v5.18;
use warnings;
use List::Util qw<none>;

sub solve {
    my @pokemons = @{$_[0]};

    my @longest_sequences = ([]);

    my @finished;
    my @st = map { [$_] } @pokemons;
    while( @st ) {
        my $seq = shift @st;
        my $letter = substr($seq->[-1], -1);
        my @next_pokemon = grep {
            my $p = $_;
            none { $_ eq $p } @$seq;
        } grep { substr($_, 0, 1) eq $letter } @pokemons;

        if (@next_pokemon) {
            for my $p (@next_pokemon) {
                push @st, [@$seq, $p];
            }
        } else {
            if (@$seq > @{ $longest_sequences[0] }) {
                @longest_sequences = ([@$seq]);

                say ">> " . join " ", @$seq;
            }
            elsif (@$seq == @{ $longest_sequences[0] }) {
                push @longest_sequences, [@$seq];
            }
        }
    }

    return \@longest_sequences;
}

my $longest_sequences = solve([qw<audino bagon baltoy banette bidoof braviary bronzor carracosta charmeleon cresselia croagunk darmanitan deino emboar emolga exeggcute gabite girafarig gulpin haxorus heatmor heatran ivysaur jellicent jumpluff kangaskhan kricketune landorus ledyba loudred lumineon lunatone machamp magnezone mamoswine nosepass petilil pidgeotto pikachu pinsir poliwrath poochyena porygon2 porygonz registeel relicanth remoraid rufflet sableye scolipede scrafty seaking sealeo silcoon simisear snivy snorlax spoink starly tirtouga trapinch treecko tyrogue vigoroth vulpix wailord wartortle whismur wingull yamask>]);

for my $seq (@$longest_sequences) {
    say join " ", @$seq;
}
