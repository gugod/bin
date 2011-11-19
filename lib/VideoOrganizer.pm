use v5.14;


package VideoOrganizer 1.00 {
    use Mouse;
    use IO::All;
    use File::Copy qw(move);

    has root => (
        isa => "Str",
        is  => "rw",
        required => 1
    );

    has collections => (
        isa => "ArrayRef[VideoOrganizer::Collection]",
        is  => "ro",
        lazy_build => 1
    );

    has mess => (
        isa => "ArrayRef[VideoOrganizer::Video]",
        is  => "ro",
        lazy_build => 1
    );

    sub _build_collections {
        my $self = shift;

        my $x = [];
        for (io($self->root)->all_dirs) {
            push @$x, VideoOrganizer::Collection->new(path => $_->name, organizer => $self)
                unless $_->filename =~ /^\./;
        }

        return $x;
    }

    sub _build_mess {
        my $self = shift;

        my $x = [];
        for (io($self->root)->all_files) {
            push @$x, VideoOrganizer::Video->new(path => $_->name, organizer => $self)
                unless $_->filename =~ /^\./;
        }

        return $x;
    }

    sub BUILD {
        my $self = shift;

        unless (-d $self->root) {
            die $self->root . " is not an directory\n";
        }

        return $self;
    }

    sub run {
        my $self = shift;

        for (@{ $self->mess }) {
            if ($_->guessed_collection) {
                move( $_->path, $_->guessed_collection->path )
            }
        }
    }
};

package VideoOrganizer::File 1.00 {
    use Mouse;
    use File::Basename;

    has organizer => (
        isa => "VideoOrganizer",
        is  => "ro",
        required => 1
    );

    has path => (
        isa => "Str",
        is  => "ro",
        required => 1
    );

    has name => (
        isa => "Str",
        is  => "ro",
        lazy_build => 1
    );

    sub _build_name {
        my $self = shift;
        return basename($self->path);
    }
}

package VideoOrganizer::Video 1.00 {
    use Mouse;
    extends 'VideoOrganizer::File';

    sub guessed_collection {
        my $self = shift;

        my @good_collections = map {
            $_->[0]
        } sort {
            length($b->[2]) <=> length($a->[2])
        } grep {
            $_->[1] >= $[
        } map {
            [$_, index($self->name, $_->name), $_->name]
        } @{$self->organizer->collections};

        return $good_collections[0];
    }
};

package VideoOrganizer::Collection 1.00 {
    use Mouse;
    extends 'VideoOrganizer::File';
};

1;
