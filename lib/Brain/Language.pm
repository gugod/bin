use v5.14;

package Brain::Language {
    use strict;
    use utf8;
    use List::MoreUtils qw(natatime);

    sub sentences {
        my ($self, $text) = @_;

        my @result;
        my $iter = natatime 2, split(/(？\」|。\」|！\」|。(?!\」))/, $text);

        while (my @vals = $iter->()) {
            local $_ = join "", @vals;
            s/( \A\s+ | \s+\Z )//x;
            push @result, $_;
        }

        return @result;
    }
};

1;
