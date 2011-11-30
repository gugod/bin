use v5.14;

package Brain {
    use Moose;
    use Brain::Blob;
    use Brain::Relation;
    use Brain::Helpers qw(sha1_hex);
    use Redis;
    use Lingua::Gram;

    has storage => (
        is => "ro",
        isa => "Redis",
        lazy => 1,
        builder => '_build_storage'
    );

    has blob => (
        is => "ro",
        isa => "Brain::Blob",
        lazy => 1,
        builder => '_build_blob'
    );

    has relation_gram_of => (
        is => "ro",
        isa => "Brain::Relation",
        lazy => 1,
        builder => '_build_relation_gram_of'
    );

    sub _build_storage {
        return Redis->new;
    }

    sub _build_blob {
        my $self = shift;
        return Brain::Blob->new(storage => $self->storage);
    }

    sub _build_relation_gram_of {
        my $self = shift;
        return Brain::Relation->new(storage => $self->storage, name => "gram_of");
    }

    sub remember {
        my ($self, $x) = @_;

        my $dx = $self->blob->add($x);
        my $lg = Lingua::Gram->new($x);

        for my $n (1..4) {
            for my $y ($lg->gram($n)) {
                my $dy = $self->blob->add($y);

                $self->relation_gram_of->add($dy, $dx);
            }
        }

        return $dx;
    }

    sub recall {
        my ($self, @units) = @_;

        my $opt = { operator => 'OR' };
        if (ref($units[-1]) eq 'HASH') {
            $opt = pop @units;
        }

        my %result;
        for my $unit (@units) {
            my $k = sha1_hex($unit);
            for (@{ $self->relation_gram_of->get($k) }) {
                $result{$_} += 1;
            }
        }

        my @results = keys %result;

        if ($opt->{operator} eq 'AND') {
            @results = grep { $result{$_} == @units } @results;
        }
        else {
            @results = sort { $result{$b} <=> $result{$a} } @results;
        }

        return map { $self->blob->get($_) } @results;
    }
};

1;
