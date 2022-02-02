
=head1 Build RE of Chinese names

Dataset:
- L<A list of Chinese Names|http://technology.chtsai.org/namelist/>

Preprocess:

    piconv -f big5 -t utf8 unique_names_2012.txt  | perl -C7 -nE 's/\r?\n\z//; m/\A\p{Han}+\z/ && say' > unique_names_2012.utf8.txt

=cut

use strict;
use warnings;

my (%first, %remaining);
while(<>) {
    chomp;
    my ($x, @y) = /(\p{Han})/g;
    $first{$x} = 1;
    $remaining{$_} = 1 for @y;
}

my $RE_first = '[' . join('', keys %first) . ']';
my $RE_remaining = '[' . join('', keys %remaining) . ']';

say $RE_first;
say $RE_remaining;
