package Sitebrew::Article;
use v5.14;
use namespace::autoclean;
use Moose;
use Sitebrew;
use File::Find;
use IO::All;
use YAML;
use Text::Markdown qw(markdown);
use DateTimeX::Easy;
use File::stat;

has content_file => (
    is => "rw",
    isa => "Str",
    required => 1
);

has title => (
    is => "rw",
    isa => "Str",
    lazy_build => 1
);

has body => (
    is => "rw",
    isa => "Str",
    lazy_build => 1
);

has body_html => (
    is => "ro",
    isa => "Str",
    lazy_build => 1
);

has published_at => (
    is => "rw",
    isa => "DateTime",
    lazy_build => 1
);

has href => (
    is => "rw",
    isa => "Str",
    lazy_build => 1
);

sub _build_title {
    my ($self) =  @_;
    my $title = io($self->content_file)->getline =~ s/^# //r =~ s/\n$//sr;
    return $title;
}

sub _build_body {
    my ($self) =  @_;
    return io($self->content_file)->all;
}

sub _build_attributes {
    my $self = shift;
    my $attr_file = $self->content_file =~ s{(/[^/]+)\.md}{$1_attributes.yml}r;

    my $attrs = {};
    if (-f $attr_file) {
        $attrs = YAML::LoadFile($self->attributes_file);
        $attrs->{published_at} = DateTimeX::Easy->parse_datetime( $attrs->{DATE} );
    }
    else {
        $attrs = {
            published_at => DateTime->from_epoch( epoch => stat($self->content_file)->mtime )
        };
    }

    $self->published_at( $attrs->{published_at} );
}

sub _build_published_at {
    my $self = shift;
    $self->_build_attributes;
    $self->published_at;
}

sub _build_href {
    my $self = shift;
    return $self->content_file =~ s{^content/}{/}r =~ s/.md$/.html/r =~ s/\/index.html$/\//r;
}

sub _build_body_html {
    my $self = shift;
    return markdown($self->body);
}

sub all {
    my ($class) = @_;

    my $app_root = Sitebrew->instance->app_root;

    my @articles;

    find({
        wanted => sub {
            return unless -f $_ && /\.md$/;

            push @articles, $class->new(content_file => $_);
        },
        no_chdir => 1,
        follow => 1
    }, io->catdir($app_root, 'content')->name);

    return @articles;
}

1;
