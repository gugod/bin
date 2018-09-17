use v5.18;
use strict;
use warnings;

=head1 Build RE of Chinese names

Dataset:
- L<A list of Chinese Names|http://technology.chtsai.org/namelist/>

Preprocess:

    piconv -f big5 -t utf8 unique_names_2012.txt  | perl -C7 -nE 's/\r?\n\z//; m/\A\p{Han}+\z/ && say' > unique_names_2012.utf8.txt

=cut

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

my (%first, %remaining);
while(<>) {
    chomp;
    next unless m/\A\p{Han}+\z/ && m/\A\p{Letter}+\z/;
    my @chars = /(\p{Han})/g;
    next unless @chars;
    $first{$chars[0]} = 1;
    $remaining{$_} = 1 for @chars[1..$#chars];
}

my $RE_first = '[' . join('', keys %first) . ']';
my $RE_remaining = '[' . join('', keys %remaining) . ']';
my $RE = "${RE_first}(?:${RE_remaining}){1,3}";

# say $RE_first;
# say $RE_remaining;
say $RE;

