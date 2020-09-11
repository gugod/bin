#!/usr/bin/env perl
use v5.28;
use Carp::Always;

package App::Feed2Epub {
    use Moo;
    use Types::Standard qw( InstanceOf ArrayRef Str );
    use EBook::EPUB::Lite;
    use XML::Feed;
    use Text::Xslate qw( mark_raw );
    use URI;
    use HTML::Scrubber;

    has 'output' => (
        is => 'ro',
        required => 1,
        isa => Str
    );

    has 'feeds' => (
        is => 'ro',
        required => 1,
        isa => ArrayRef[InstanceOf['XML::Feed']],
        coerce => sub {
            my @feeds = @{$_[0]};
            my @r;
            my $type = InstanceOf['XML::Feed'];
            for my $it (@feeds) {
                if ($type->check($it)) {
                    push @r, $it
                } else {
                    my $feed = XML::Feed->parse(URI->new($it)) or die XML::Feed->errstr;
                    push @r, $feed;
                }
            }
            return \@r;
        }
    );

    sub u {
        my $str = $_[0];
        return $str if utf8::is_utf8($str);
        utf8::decode($str);
        return $str;
    }

    sub format_content {
        my $content = $_[0];
        my $scrubber = HTML::Scrubber->new( allow => [ qw[ p b i u hr br ] ] );
        $content = $scrubber->scrub($content);
        return $content;
    }

    sub run {
        my ($self) = @_;

        my $template = <<'EOF';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title><: $title :></title>
</head>
<body>
  <article>
    <h3><: $title :></h3>
    <div><: $content :></div>
  </article>
</body></html>
EOF

        my $epub = EBook::EPUB::Lite->new;
        $epub->add_title('Feeds');
        $epub->add_author($ENV{USER} // 'nobody');
        $epub->add_language('zh-Hant');

        my $idx = 1;
        for my $feed (@{ $self->feeds }) {
            for my $entry ($feed->entries) {
                my $page = "page_${idx}.xhtml";
                my $content = $entry->content->body // $entry->summary->body;

                my %vars = (
                    title   => u( $entry->title ),
                    content => mark_raw( format_content( u($content) )),
                );

                my $xhtml = Text::Xslate->new()->render_string($template, \%vars);
                my $id = $epub->add_xhtml( $page, $xhtml, linear => "yes");
                my $np = $epub->add_navpoint(
                    label   => $vars{title},
                    id      => $id,
                    content => $page,
                );
                $idx++;
            }
        }

        $epub->pack_zip( $self->output() );
    }
};

use Getopt::Long qw(GetOptions);
# main
my %opts;
GetOptions(
    \%opts,
    "o=s",
);
die "Required '-o' option to be /path/of/output.epub\n" unless $opts{o} and not -e $opts{o};

App::Feed2Epub->new(
    feeds => [ @ARGV ],
    output => $opts{o},
)->run();
