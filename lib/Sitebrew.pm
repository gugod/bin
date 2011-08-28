package Sitebrew;
use Moose;
use MooseX::Singleton;
use IO::All;

has app_root => (
    is => "rw",
    isa => "Str",
    required => 1
);

has config => (
    is => "rw",
    isa => "Sitebrew::Config",
    lazy_build => 1
);

sub _build_articles {
    my ($self) = @_;
    return [];
}

sub _build_config {
    my ($self) = @_;
    require Sitebrew::Config;
    Sitebrew::Config->load( io->catfile($self->app_root, ".sitebrew", "config.yml") );
}


1;
