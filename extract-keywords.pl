#!/usr/bin/env perl

use v5.16;
use utf8;
use encoding 'utf8';
use List::MoreUtils qw(uniq);
use Memoize;

sub flip($) { join "" => reverse split "", $_[0] }

sub _chars {
    my ($context, $str) = @_;
    if ($context == 1) {
        return length($str);
    }
    elsif ($context == 2) {
        return split "" => $str;
    }
    return;
}
memoize '_chars';

sub chars($) {
    my $wantlist = wantarray;
    return _chars( defined($wantlist) ? ( $wantlist ? 2 : 1 ) : 0, $_[0]);
}

# longest common prefix
sub lcp($$) {
    my ($str1, $str2) = @_;
    my @chars1 = chars($str1);
    my @chars2 = chars($str2);

    my @common;

    for my $i (0..$#chars1) {
        if ($chars2[$i] && $chars1[$i] eq $chars2[$i]) {
            push @common, $chars1[$i];
        }
        else {
            last;
        }
    }
    return join("", @common);
}

sub suffixes {
    my ($str, $min_chars, $max_chars) = @_;
    $min_chars ||= 1;
    $max_chars ||= 1024;
    my $chars = chars($str);
    return grep { chars($_) >= $min_chars && chars($_) <= $max_chars } map { substr($str, $_) } 0..$chars-1;
}

sub suffix_lcp {
    my @suffixes = @_;
    my @lcp;
    for my $i (0..$#suffixes-1) {
        $lcp[$i] = lcp($suffixes[$i], $suffixes[$i+1]);
    }
    return uniq grep {$_} @lcp;
}

sub trim_spaces {
    grep { $_ } map { s/\n//gu; s/^\s+//; $_ } @_
}

sub ignore_punctuations {
    grep { !( /^\p{Punct}/u ) } @_;
}

sub ignore_all_latin {
    grep { ! /^\p{Alpha}+$/u } @_;
}

sub spectrum {
    my $input = shift;
    return memoize(
        sub {
            my ($token) = @_;
            return $input =~ s/\Q$token\E/$token/g;
        }
    );
}

my $input = do {
    local $/ = undef;
    my $in = <>;
    utf8::decode($in);
    $in;
};

my $frequency = spectrum($input);

my @strs = grep { $_ } split /(?:\p{Punct}|\s)/u, $input;

my @suffixes = uniq sort map { suffixes($_) } @strs;
my @suffix_lcp = suffix_lcp(@suffixes);

my %significance;
for my $token (sort { chars($a) <=> chars($b) } @suffix_lcp) {
    my $a = $token =~ s/^\p{Any}//ur;
    my $b = $token =~ s/\p{Any}$//ur;

    if (chars($token) > 1) {
        my $f  = $frequency->($token);
        my $fa = $frequency->($a);
        my $fb = $frequency->($b);

        if ($fa && $fb) {
            if ($f == $fa + $fb) {
                $significance{$token} = 0;
            }
            else {
                $significance{$token} = $f / ($fa + $fb - $f);
                delete $significance{$a};
                # delete $significance{$b};
            }
        }
    }
    else {
        $significance{$token} = 0;
    }
}

for(sort { $significance{$b} <=> $significance{$a} || $frequency->($b) <=> $frequency->($a) } keys %significance) {
    next unless $significance{$_} > 0;
    # next unless $significance{$_} == 1;
    say sprintf("%4d\t%0.4f\t%s", $frequency->($_), $significance{$_}, $_);
    # say sprintf("%d\t%s", $frequency->($_), $_);
}
