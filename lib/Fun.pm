package Fun;
use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw'is_perl foreach_perl_source_file';

use File::Basename 'basename';
use File::Next;

sub is_perl {
    my ($file) = @_;

    return 1 if $file =~ / \.(?: t|p[ml]|pod|comp|psgi ) $/xi;
    return 0 if basename($file) =~ / \. /xi;

    if (open my $fh, '<', $file) {
        my $line = <$fh>;
        return 1 if $line && $line =~ m{^#!.*perl};
    }

    return 0;
}

sub foreach_perl_source_file {
    my ($input, $cb) = @_;
    for (@$input) {
        my $files = File::Next::files($_);
        while ( defined ( my $file = $files->() ) ) {
            next unless is_perl($file);
            $cb->($file);
        }
    }
}

1;
