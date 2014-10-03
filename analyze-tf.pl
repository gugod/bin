#!/usr/bin/env perl
use v5.18;
use utf8;

use IO::All;
use YAML ();
use Unicode::UCD qw(charscript);
use List::MoreUtils qw(uniq);
use List::PowerSet qw(powerset);
use Sereal::Encoder;
use Sereal::Decoder;

sub tokenize_by_script {
    my $str = shift;
    my @tokens;
    my @chars = split "", $str;
    my $t = shift(@chars);
    my $s = charscript(ord($t));
    while(my $char = shift @chars) {
        my $_s = charscript(ord($char));
        if ($_s eq $s) {
            $t .= $char;
        }
        else {
            push @tokens, $t;
            $s = $_s;
            $t = $char;
        }
    }
    push @tokens, $t;
    return @tokens;
}

sub tokenize {
    return tokenize_by_script($_[0])
}

sub char_filter {
    my $str = $_[0];
    $str =~ s!\s+! !g;
    return $str;
}

sub ngram {
    my ($str, $n) = @_;
    my @chars = split "", $str;
    my @tokens = ();
    for (my $i = 0; $i < @chars - $n + 1; $i++) {
        push @tokens, join("", @chars[$i .. $i+$n-1]);
    }
    return @tokens;
}

sub filter {
    return map {
        my @o;
        if (/\p{Han}/) {
            @o = ($_, ngram($_, 3), ngram($_, 2), split("", $_));
        }
        else {
            @o = ($_)
        }

        @o;
    } @_;
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
        my @token = filter tokenize char_filter $_;

        my %seen;
        for my $token (@token) {
            $idx->{tf}{$token}++;
            push( @{ $idx->{doc}{$token} ||=[] }, $line_number) unless $seen{$token}++;
        }

        $idx->{doc_count}++;

        # last if $line_number > 10;
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
my $idx;
my $idx_file = "/tmp/the_index.sereal";
if (-f $idx_file) {
    my $decoder = Sereal::Decoder->new();
    $decoder->decode( scalar(io($idx_file)->all), $idx );
}
else {
    $idx = build_index( io($txt)->utf8 );
    my $encoder = Sereal::Encoder->new();
    io($idx_file)->print( $encoder->encode($idx) );
}
die unless $idx;

my @terms = ("王", "金", "平", "王金", "金平", "王金平");
binmode STDOUT, ":utf8";
my $res = search($idx, \@terms);
my $ro = $res->{ro};
say YAML::Dump($res->{ro});

say "Confidence(王金 => 王金平) = " . $ro->{"王金平"} / $ro->{"王金"};
say "Confidence(金平 => 王金平) = " . $ro->{"王金平"} / $ro->{"金平"};
say "Confidence(王   => 王金平) = " . $ro->{"王金平"} / $ro->{"王"};
say "Confidence(金   => 王金平) = " . $ro->{"王金平"} / $ro->{"金"};
say "Confidence(平   => 王金平) = " . $ro->{"王金平"} / $ro->{"平"};
