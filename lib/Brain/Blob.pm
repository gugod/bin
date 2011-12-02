use v5.14;

package Brain::Blob {
    use Moose;
    use Brain::Helpers qw(sha1_hex);

    has storage => (
        is => "ro",
        required => 1,
        isa => "Redis"
    );

    sub add {
        my $self = shift;
        my $text = shift;

        my $k = sha1_hex($text);

        $self->storage->hset("brain_blob", $k, $text);

        return $k;
    }

    sub get {
        my $self = shift;
        my $k = shift;
        return $self->storage->hget("brain_blob", $k);
    }

    sub remove {
        my ($self, $k) = @_;
        return $self->storage->hdel("brain_blob", $k);
    }
};

1;
