package Sitebrew::Article;
use Moose;

has title => (
    is => "rw",
    isa => "Str",
    required => 1
);

has body => (
    is => "rw",
    isa => "Str",
    required => 1
);

has published_at => (
    is => "rw",
    isa => "DateTime",
    required => 1
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;
