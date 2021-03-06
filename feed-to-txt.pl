#!/usr/bin/env perl
use v5.28;

package App::Feed2Txt {
    use Moo;
    use Types::Standard qw( InstanceOf ArrayRef Str );
    use XML::Loy;
    use URI;
    use Mojo::UserAgent;
    use NewsExtractor;
    use Importer 'NewsExtractor::TextUtil' => ('html2text', 'normalize_whitespace');

    has 'output' => (
        is => 'ro',
        required => 1,
        isa => Str,
    );

    has 'feed_urls' => (
        is => 'ro',
        required => 1,
        isa => ArrayRef[InstanceOf['URI']],
        coerce => sub {
            [ map { URI->new($_) } @{$_[0]} ]
        }
    );

    sub run {
        my ($self) = @_;
        my $ua = Mojo::UserAgent->new;

        my @entries;
        for my $url (@{ $self->feed_urls }) {
            my $tx = $ua->get("".$url);
            my $xml = $tx->result->dom;

            # atom or rss;
            $xml->find("entry, item")->each(
                sub {
                    my $el = $_;

                    my %entry;
                    for my $it (["title", "title"],
                                ["author > name, creator", "author"],
                                ["updated, published, pubDate", "published_at"],
                                ["content, summary, description", "content"]) {
                        my ($csssel, $attr) = @$it;
                        if (my $el_attr = $el->at($csssel)) {
                            $entry{$attr} = $el_attr->all_text;
                        }
                    }

                    $entry{link} = $_->attr("href") if $_ = $el->at('link[rel="alternate"]') // $el->at('link[href]');

                    if ($entry{title} && $entry{content}) {
                        push @entries, \%entry;
                    }
                }
            );
        }

        open(my $ofh, '>', $self->output());
        my $border = (" " x30).(join(" ",("~")x8)).(" "x30);
        for my $e (@entries) {
            my $txt = $self->render($e);
            utf8::encode($txt);
            print $ofh $txt . "\n\n$border\n\n";
        }
        close($ofh);
    }

    sub render {
        my ($self, $vars) = @_;

        my @lines = ("Title: $vars->{title}");
        push @lines, "Author: " . html2text($vars->{author}) if $vars->{author};
        push @lines, "Published at: $vars->{published_at}" if $vars->{published_at};
        push @lines, "Link: $vars->{link}" if $vars->{link};
        push @lines, "\n" . html2text($vars->{content}) . "\n";
        return join "\n", @lines;
    }
};

use Getopt::Long qw(GetOptions);
# main
my %opts;
GetOptions(
    \%opts,
    "o=s",
);
die "Required '-o' option to be /path/of/output.txt\n" unless $opts{o} and not -e $opts{o};

App::Feed2Txt->new(
    feed_urls => [ @ARGV ],
    output    => $opts{o},
)->run();
