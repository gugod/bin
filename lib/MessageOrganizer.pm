use v5.18;

package MessageOrganizer {
    use Moo;
    use Email::MIME;
    use Encode 'decode_utf8';
    use List::Util qw(max sum);
    use List::MoreUtils qw(uniq);

    use Tokenize;

    has idx => (
        is => "ro",
        required => 1,
    );

    sub looks_like {
        my ($self, $message) = @_;

        my $email = Email::MIME->new($message);
        my $idx = $self->idx;
        my $doc = {
            subject => decode_utf8( $email->header("Subject"), Encode::FB_QUIET ),
            from    => decode_utf8( $email->header("From"), Encode::FB_QUIET ),
        };

        my %guess;

        for my $field (keys %$doc) {
            my @tokens = Tokenize::standard_than_shingle2($doc->{$field}) or next;

            my (%matched, %score);
            for my $category (keys %$idx) {
                for (@tokens) {
                    $matched{$_} = $idx->{$category}{field}{$field}{token}{$_}{count_document} || 0;
                }
                my $count_matched = sum(map { $_ ? 1 : 0 } values %matched) || 0;
                $score{$category} = $count_matched / @tokens;
            }

            my @c = sort { $score{$b} <=> $score{$a} } keys %score;

            $guess{$field} = {
                fieldLength => 0+@tokens,
                category   => $c[0],
                confidence => $score{$c[0]} / (sum(values %score) ||1),
                categories => \@c,
                score => \%score,
            };
        }

        my @guess = keys %guess;
        my $category;
        if (@guess > 0) {
            if (1 == uniq(map { $guess{$_}->{category} } @guess)) {
                my $g = $guess{ $guess[0] };
                if ($g->{confidence} > 0.9) {
                    $category = $g->{category};
                }
            }
            else {
                # unsure
                # say "(???)\t$doc->{subject}";
                # say "\t" . $json->encode(\%guess);
                # say "\t".join "," => map { $_ . ":" . sprintf('%.2f', $score{$_} ) } @c;
            }
        }
        else {
            # unsure
        }

        return $category;
    }

};
1;
