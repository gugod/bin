use v5.14;

package Brain {
    use Moose;
    use Brain::Blob;
    use Brain::Relation;
    use Brain::Language;
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
        state $relations = {};

        my ($self, $name) = @_;
        die unless $name;

        return $relations->{$name} ||= Brain::Relation->new(storage => $self->storage, name => $name);
    }

    sub study {
        my ($self, $text) = @_;

        my $k_text = $self->blob->add($text);

        my @sentences = Brain::Language->sentences($text);

        my $k_last;
        for my $x (@sentences) {
            my $k = $self->remember($x);
            $self->relation("appear_in")->add($k, $k_text);

            if ($k_last) {
                $self->relation("precede")->add($k, $k_last);
                $self->relation("follow")->add($k_last, $k);
            }
            $k_last = $k;
        }

        return $k_text;
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

        return @results;
    }
};

1;
