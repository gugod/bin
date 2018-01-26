package Fun;
use strict;
use warnings;
use parent 'Exporter';

our @EXPORT_OK = qw'is_perl';

sub is_perl {
    my ($file) = @_;

    return 1 if $file =~ / \.(?: t|p[ml]|pod|comp ) $/xi;
    return 0 if $file =~ / \. /xi;

    if (open my $fh, '<', $file) {
        my $line = <$fh>;
        return 1 if $line && $line =~ m{^#!.*perl};
    }

    return 0;
}

1;

