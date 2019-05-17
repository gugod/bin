package Fun;
use v5.18;
use warnings;

use Exporter 'import';
use Module::Functions;
our @EXPORT_OK = get_public_functions();

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

sub hash_left_merge {
    my ($h1, $h2) = @_;
    for (keys %$h2) {
        $h1->{$_} //= $h2->{$_};
    }
    return;
}

1;
