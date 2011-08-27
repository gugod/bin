package Sitebrew::Config;
use Moose;

has title => (
    is => "rw",
    isa => "Str"
);

has url_base => (
    is => "rw",
    isa => "Str",
    required => 1
);

use namespace::autoclean;
use YAML ();

sub load {
    my ($class, $file) = @_;
    my $config = YAML::LoadFile($file);

    return $class->new(%$config);
}

no Moose;
1;
