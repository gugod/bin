package Sitebrew;
use MooseX::Singleton;
use IO::All;
use Text::Markdown ();
use DateTime::TimeZone;
use Sitebrew::Config;

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

has local_time_zone => (
    is => "ro",
    isa => "DateTime::TimeZone",
    lazy_build => 1
);

sub _build_config {
    my $self = shift;
    Sitebrew::Config->load( io->catfile($self->app_root, ".sitebrew", "config.yml") );
}

sub _build_local_time_zone {
    DateTime::TimeZone->new(name => 'local');
}

sub markdown {
    my ($self, $text, @options) = @_;

    # github markup
    $text =~ s{(?<!`)\[\[([^\n]+?)\]\](?!`)}{
        my $label = $1;
        my $page = $1 =~ s{ }{-}gr =~ s{/}{-}gr;

        "[$label]($page.html)"
    }eg;

    Text::Markdown::markdown( $text, @options );
}

1;
