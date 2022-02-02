use v5.28;
use strict;

use FindBin;
use lib $FindBin::Bin . "/../lib";

use RE;
use Tokenize;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

# my $re = RE::chinese_name;
my $re = RE::chinese_full_name;

my $content = do { undef $/; <> };
my @p = grep { $_ ne '' } split /(?:\p{Punct}|\s)/, $content;

my @matched;
for my $p (@p) {
    my $i = 0;
    my $prefix = qr(\p{Any}+);
    # say ">>> $p";
    while ($p =~ /($re)/g) {
        push @matched, $1;
        $p = substr($p, pos($p) - length($1) + 1);
    }
}
say for @matched;
