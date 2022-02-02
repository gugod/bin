#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Encode qw(encode_utf8 decode_utf8);
use YAML;

sub longest_common_prefix {
    my ($x, @xs) = @_;
    my $len = 2;
    my $prefix = substr($x, 0, $len);
    while ( $len <= length($x) && (@xs == grep { index($_, $prefix, 0) == 0 } @xs) ) {
        $prefix = substr($x, 0, ++$len);
    }
    return substr($x, 0, $len - 1);
}

my %phrases;
my %prefix;
my @titles = uniq map { decode_utf8($_) } <>;
my $new_phrases = 1;
my $step = 0;
while($new_phrases && @titles) {
    $new_phrases = 0;
    $step++;

    for (grep { $_ ne '' } map { split /\s*\p{Punct}\s*|\s+/ } @titles) {
        # say ">>> " . encode_utf8($_);
        my $tok = substr($_, 0, 2);
        push @{$prefix{$tok}}, $_;
    }
    @titles = ();

    for my $tok (keys %prefix) {
        if (@{$prefix{$tok}} > 1) {
            my $phrase = longest_common_prefix(@{$prefix{$tok}});
            $phrases{$phrase} = $step;
            $new_phrases++;
            say encode_utf8($step . "\t" . $phrase);
            push @titles, grep { $_ ne '' }  map { substr($_, length($phrase)) = '' } @{delete $prefix{$tok}};
        } else {
            push @titles, @{delete $prefix{$tok}};
        }
    }
}

# for (keys %phrases) {
#     say encode_utf8( $phrases{$_} . "\t" . $_ );
# }
