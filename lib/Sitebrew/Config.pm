package Sitebrew::Config;
use Moose;
use MooseX::Types::URI qw(Uri);

has title => (
    is => "rw",
    isa => "Str"
);

has url_base => (
    is => "rw",
    isa => Uri,
    required => 1,
    coerce => 1
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
