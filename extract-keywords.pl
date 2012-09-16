#!/usr/bin/env perl

use v5.16;
use utf8;
use encoding 'utf8';
use List::MoreUtils qw(uniq);
use Memoize;

sub flip($) { join "" => reverse split "", $_[0] }

sub _chars_length($) {
    return length($_[0])
}
memoize('_chars_length');

sub chars($) {
    my $wantlist = wantarray;

    if (!defined($wantlist)) {
        return;
    }
    elsif ($wantlist) {
        return split "" => $_[0];
    }
    else {
        return _chars_length($_[0]);
    }
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
    return grep { chars($_) >= $min_chars } map { ( substr($str, $_, $max_chars) ) } 0..$chars-1;
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

sub total_frequency {
    my ($input, @tokens) = @_;
    my %freq;
    for my $k (@tokens) {
        $freq{$k} = $input =~ s/\Q$k\E/$k/g;
    }

    return %freq;
}

sub token_frequency {
    my ($input, $token) = @_;
    return $input =~ s/\Q$token\E/$token/g;
}

memoize('token_frequency');

my $input = do {
    local $/ = undef;
    my $in = <>;
    utf8::decode($in);
    $in;
};

my @strs = grep { $_ } split /(?:\p{Punct}|\s)/u, $input;

my @suffixes = uniq sort map { suffixes($_) } @strs;
my @suffix_lcp = suffix_lcp(@suffixes);

my %significance;
for my $token (sort { chars($a) <=> chars($b) } @suffix_lcp) {
    my $a = $token =~ s/^\p{Any}//ur;
    my $b = $token =~ s/\p{Any}$//ur;

    if (chars($a) > 0 && chars($b)>0) {
        my $f  = token_frequency($input, $token);
        my $fa = token_frequency($input, $a);
        my $fb = token_frequency($input, $b);

        if (defined($fa) && defined($fb)) {
            if ($f == $fa + $fb) {
                $significance{$token} = 0;
            }
            else {
                $significance{$token} = $f / ($fa + $fb - $f);
                delete $significance{$a};
                delete $significance{$b};
            }
        }
    }
    else {
        $significance{$token} = 0;
    }
}

for(sort { $significance{$b} <=> $significance{$a} } keys %significance) {
    next unless $significance{$_} > 0;
    say "$_\t" . token_frequency($input, $_) . "\t" . $significance{$_};
}
