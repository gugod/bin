#!/usr/bin/env perl
use v5.18;
use utf8;

use IO::All;
use YAML ();
use List::MoreUtils qw(uniq);
use List::PowerSet qw(powerset);

sub tokenize {
    my $str = $_[0];
    split "", $str;
}

sub char_filter {
    my $str = $_[0];
    $str =~ s!\s+! !g;
    return $str;
}

sub build_index {
    my ($fh_txt) = @_;
    my $idx = {
        tf => {},
        doc => {},
        doc_count => 0,
    };
    my $line_number = 0;

    while ( $_ = $fh_txt->getline ) {
        $line_number++;
        my @token = tokenize char_filter $_;

        my %seen;
        for my $token (@token) {
            $idx->{tf}{$token}++;
            push( @{ $idx->{doc}{$token} ||=[] }, $line_number) unless $seen{$token}++;
        }

        $idx->{doc_count}++;
    }

    return $idx;
}

sub search {
    my ($idx, $terms) = @_;
    my %doc_id;
    my %ro;

    for my $t (@$terms) {
        for(@{ $idx->{doc}{$t} }) {
            $doc_id{$_} += 1;
        }
        $ro{$t} = @{ $idx->{doc}{$t} };
    }

    for my $term_set (grep { @$_ > 1 } @{powerset(@$terms)}) {
        my %seen;
        for my $t (@$term_set) {
            $seen{$_} += 1 for @{ $idx->{doc}{$t} };
        }
        my $ro_key = join " ", @$term_set;
        $ro{$ro_key} = grep { $seen{$_} == @$term_set } keys %seen;
    }

    return {
        hits => [ sort { $doc_id{$b} <=> $doc_id{$a} || $a<=>$b } keys %doc_id ],
        ro => \%ro,
    }
}

my $txt = shift @ARGV || die;
my $idx = build_index( io($txt)->utf8 );

my @terms = qw(王 金 平);
binmode STDOUT, ":utf8";
my $res = search($idx, \@terms);
my $ro = $res->{ro};
say YAML::Dump($res->{ro});


say "Confidence(王金 => 王金平) = " . ( $ro->{"王 金 平"} / $ro->{"王 金"} );
say "Confidence(金平 => 王金平) = " . ( $ro->{"王 金 平"} / $ro->{"金 平"} );
say "Confidence(王平 => 王金平) = " . ( $ro->{"王 金 平"} / $ro->{"王 平"} );
