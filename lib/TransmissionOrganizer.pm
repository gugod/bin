use v5.14;

package TransmissionOrganizer 1.0 {
    use Moose;
    use Transmission::Client;

    has options => (
        is => "rw",
        isa => "HashRef",
        required => 1
    );

    has transmission_client => (
        is => "rw",
        isa => "Transmission::Client",
        lazy_build =>1
    );

    has finished_torrents => (
        is => "rw",
        isa => "ArrayRef",
        lazy_build => 1
    );

    sub _build_transmission_client {
        my $self = shift;
        my %opts = ( autodie => 1 );

        for (grep { defined($_->[1]) } map { [$_, $self->options->{$_}] } qw(url username password)) {
            $opts{$_->[0]} = $_->[1];
        }

        return Transmission::Client->new(%opts);
    }

    sub _build_finished_torrents {
        my $self = shift;
        my @r = ();
        for my $torrent (@{ $self->transmission_client->torrents }) {
            if ($torrent->status eq '16' && 1 == @{$torrent->files} ) {
                push @r, $torrent;
            }
        }
        return \@r;
    }

    sub run {
        my $self = shift;

        for my $torrent (@{ $self->finished_torrents }) {
            say $torrent->name;
            for my $file (@{ $torrent->files }) {
                say $torrent->download_dir . "/" . $file->name;
            }
            say "-" x 42;
        }
    }
};

1;
