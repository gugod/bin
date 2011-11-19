use v5.14;

package FileOrganizer 1.00 {
    use Moose;
    use IO::All -utf8;
    use File::Copy qw(move);

    has root => (
        isa => "Str",
        is  => "rw",
        required => 1
    );

    has collections => (
        isa => "ArrayRef[FileOrganizer::Collection]",
        is  => "ro",
        lazy_build => 1
    );

    has mess => (
        isa => "ArrayRef[FileOrganizer::File]",
        is  => "rw",
        lazy_build => 1
    );

    sub _build_collections {
        my $self = shift;

        my $x = [];
        for (io($self->root)->all_dirs) {
	    my $fname = $_->name;
	    utf8::decode($fname) unless utf8::is_utf8($fname);

            push @$x, FileOrganizer::Collection->new(path => $fname, organizer => $self)
                unless $_->filename =~ /^\./;
        }

        return $x;
    }

    sub _build_mess {
        my $self = shift;

        my $x = [];
        for (io($self->root)->all_files) {
            push @$x, FileOrganizer::File->new(path => $_->name, organizer => $self)
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

package FileOrganizer::File 1.00 {
    use Moose;
    use File::Basename;
    use Encode::HanConvert ();
    use File::Copy qw(move);

    has organizer => (
        isa => "FileOrganizer",
        is  => "ro",
        required => 1
    );

    has path => (
        isa => "Str",
        is  => "rw",
        required => 1
    );

    has name => (
        isa => "Str",
        is  => "rw",
        lazy_build => 1
    );

    sub _build_name {
        my $self = shift;
        return basename($self->path);
    }

    sub rename_to_traditional_chinese {
	my $self = shift;
	my $new_name = Encode::HanConvert::trad( $self->name );
	return if $new_name eq $self->name;

	my $new_path = dirname($self->path) . "/" . $new_name;
	return if -f $new_path;

	move($self->path, $new_path);

	$self->path( $new_path );
	$self->name( $self->_build_name );
    }

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
}

package FileOrganizer::Collection 1.00 {
    use Moose;
    extends 'FileOrganizer::File';
};

1;
