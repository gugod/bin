use v5.14;

package Brain::Relation {
    use Moose;

    has name => (
        is => "rw",
        isa => "Str",
        required => 1
    );

    has storage => (
        is => "ro",
        required => 1,
        isa => "Redis"
    );

    sub _redis_key {
        my $self = shift;
        my $x = shift;
        return "brain_relation_" . $self->name . "_${x}";
    }

    sub add {
        my ($self, $x, $y) = @_;
        $self->storage->sadd( $self->_redis_key($x), $y);
    }

    sub get {
        my ($self, $x) = @_;
        $self->storage->smembers( $self->_redis_key($x) );
    }
};

1;

