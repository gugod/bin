use v5.14;

package Brain {
    use Moose;
    use Brain::Blob;
    use Brain::Relation;
    use Brain::Language;
    use Brain::Helpers qw(sha1_hex);
    use Redis;
    use Lingua::Gram;
    use Ceis::Extractor;
    use Regexp::Common qw/URI/;

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

    has extractor => (
        is => "rw",
        isa => "Ceis::Extractor",
        lazy => 1,
        builder => '_build_extractor'
    );

    sub _build_storage {
        return Redis->new;
    }

    sub _build_blob {
        my $self = shift;
        return Brain::Blob->new(storage => $self->storage);
    }

    sub _build_extractor {
        return Ceis::Extractor->new;
    }

    sub relation {
        state $relations = {};

        my ($self, $name) = @_;
        die unless $name;

        return $relations->{$name} ||= Brain::Relation->new(storage => $self->storage, name => $name);
    }

    sub study {
        my ($self, $thing) = @_;

        my ($fulltext, $k_fulltext);

        if ($thing =~ /\A$RE{URI}{HTTP}{-scheme=>"https?"}\Z/) {
            $self->extractor->url($thing);

            $fulltext = $self->extractor->fulltext;

            my $k_url   = $self->blob->add($self->extractor->url);
            $k_fulltext = $self->blob->add($fulltext);

            $self->relation("origin")->add($k_fulltext, $k_url);
        }
        else {
            $fulltext   = $thing;
            $k_fulltext = $self->blob->add($fulltext);
        }

        my $k_last;
        for my $x ( Brain::Language->sentences($fulltext) ) {
            my $k = $self->remember($x);
            $self->relation("appear")->add($k, $k_fulltext);

            if ($k_last) {
                $self->relation("precede")->add($k, $k_last);
                $self->relation("follow")->add($k_last, $k);
            }
            $k_last = $k;
        }

        return $k_fulltext;
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

    # The relations of a blob-key.
    sub relations {
        my ($self, $k) = @_;
        my $rel = {};

        for (qw(appear origin)) {
            $rel->{$_} = $self->relation($_)->get($k);
        }

        if (@{$rel->{appear}} && !@{ $rel->{origin} }) {
            $rel->{origin} = [ map { $self->relation("origin")->get( $_ ) } @{ $rel->{appear} } ];
        }

        if (@{$rel->{origin}}) {
            $rel->{origin} = [ map { $self->blob->get($_) } @{$rel->{origin}} ];
        }

        return $rel;
    }

};

1;
