package Sitebrew::Article;
use v5.14;

use Moose;
use utf8;
use File::Find;
use IO::All -utf8;
use YAML;
use Text::Markdown qw(markdown);
use File::stat;

use Sitebrew;
use DateTime;
use DateTimeX::Easy;

has content_file => (
    is => "rw",
    isa => "Str",
    required => 1
);

has title => (
    is => "rw",
    isa => "Str",
    lazy => 1,
    builder => "_build_title"
);

has body => (
    is => "rw",
    isa => "Str",
    lazy => 1,
    builder => "_build_body"
);

has published_at => (
    is => "rw",
    isa => "DateTime",
    lazy => 1,
    builder => "_build_published_at"
);

has href => (
    is => "rw",
    isa => "Str",
    lazy => 1,
    builder => "_build_href"
);

sub _build_title_and_body {
    my ($self) = @_;
    my $content_text = io($self->content_file)->utf8->all;
    my ($first_line) = $content_text =~ m/\A(.+)\n/;

    my $title = $first_line =~ s/^#+ //r;

    $content_text =~ s/\A(.+)\n//;
    $content_text =~ s/\A(=+)\n//;

    $self->title($title);
    $self->body($content_text);
}

sub _build_title {
    my ($self) =  @_;
    $self->_build_title_and_body;
    return $self->title;
}

sub _build_body {
    my ($self) =  @_;
    $self->_build_title_and_body;
    return $self->body;
}

sub _build_published_at {
    my $self = shift;
    my $attr_file = $self->content_file =~ s{(/[^/]+)\.md}{$1_attributes.yml}r;

    my $attrs = {};

    if (-f $attr_file) {
        $attrs = YAML::LoadFile($attr_file);
        $attrs->{published_at} = DateTimeX::Easy->parse_datetime( $attrs->{DATE} );
    }
    else {
        $attrs->{published_at} = DateTime->from_epoch( epoch => stat($self->content_file)->mtime );
    }

    $attrs->{published_at}->set_time_zone( Sitebrew->local_time_zone );

    return $attrs->{published_at};
}

sub _build_href {
    my $self = shift;
    return $self->content_file =~ s{^content/}{/}r =~ s/.md$/.html/r =~ s/\/index.html$/\//r;
}

sub each {
    my ($class, $cb) = @_;
    my $app_root = Sitebrew->instance->app_root;

    my @content_files;

    find({
        wanted => sub {
            return unless -f $_ && /\.md$/;
            push @content_files, $_;
        },
        no_chdir => 1,
        follow => 1
    }, io->catdir($app_root, 'content')->name);

    for my $content_file (@content_files) {
        my $article = $class->new(content_file => $content_file);
        $cb->($article);
    }
}

sub all {
    my ($class) = @_;

    my @articles;

    $class->each(
        sub {
            push @articles, $_[0]
        }
    );

    return sort { $b->published_at <=> $a->published_at } @articles;
}

1;
