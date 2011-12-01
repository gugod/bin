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

    sub _build_storage {
        return Redis->new;
    }

    sub _build_blob {
        my $self = shift;
        return Brain::Blob->new(storage => $self->storage);
    }

    sub relation {
        my ($self, $name) = @_;
        die unless $name;

        return Brain::Relation->new(storage => $self->storage, name => $name);
    }

    sub remember {
        my ($self, $x) = @_;

        my $dx = $self->blob->add($x);
        my $lg = Lingua::Gram->new($x);

        my $gramrel = $self->relation('gram_of');

        for my $n (1..4) {
            for my $y ($lg->gram($n)) {
                my $dy = $self->blob->add($y);

                $gramrel->add($dy, $dx);
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

        my $gramrel = $self->relation('gram_of');

        my %result;
        for my $unit (@units) {
            my $k = sha1_hex($unit);
            for (@{ $gramrel->get($k) }) {
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
