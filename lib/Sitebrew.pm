package Sitebrew;
use MooseX::Singleton;
use IO::All;
use Text::Markdown ();
use DateTime::TimeZone;
use Sitebrew::Config;
use Sitebrew::Article;
use Text::Xslate;

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

sub helpers {
    my ($self) = @_;
    return {
        markdown => sub {
            my $t = shift;
            return Text::Xslate::mark_raw(
                Sitebrew->markdown($t, { empty_element_suffix => '>' } )
            )
        },

        articles => sub {
            my $n = shift;

            if (defined($n) && $n > 0) {
                return [Sitebrew::Article->first($n)]
            }
            return [Sitebrew::Article->all]
        }
    }
}

1;
