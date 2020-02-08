#!/usr/bin/env perl
use v5.28;

package App::Feed2Txt {
    use Moo;
    use Types::Standard qw( InstanceOf ArrayRef Str );
    use XML::Loy;
    use URI;
    use Mojo::UserAgent;
    use Importer 'NewsExtractor::TextUtil' => ('html2text', 'normalize_whitespace');

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
            # rss
            $xml->find("item")->each(
                sub {
                    my $el = $_;
                    my ($author, $published_at);
                    $author = $_->text if $_ = $el->at("creator");
                    $published_at = $_->text if $_ = $el->at("date, pubDate");

                    push @entries, {
                        title => $el->at("title")->text,
                        content => $el->at("description")->text,
                        author => $author // 'Unknown',
                        published_at => $published_at // 'Unknown',
                    }
                }
            );

            # atom;
            $xml->find("entry")->each(
                sub {
                    my $el = $_;
                    my ($author, $published_at);
                    $author = $_->text if $_ = $el->at("author > name");
                    $published_at = $_->text if $_ = $el->at("updated");

                    push @entries, {
                        title => $el->at("title")->text,
                        content => $el->at("content")->text,
                        author => $author // '(Unknown)',
                        published_at => $published_at // '(Unknown)',
                    }
                }
            );
        }

        for my $e (@entries) {
            my $txt = $self->render($e);
            utf8::encode($txt);
            print $txt;
        }
    }

    sub render {
        my ($self, $vars) = @_;
        my $border = (" " x30).(join(" ",("~")x8)).(" "x30);
        return ($border . "\n" .
                'Title: ' . $vars->{title} . "\n" .
                'Author: ' . $vars->{author} . "\n" .
                "published_at: " . $vars->{published_at} . "\n" .
                "\n" .
                html2text($vars->{content}) .
                "\n\n" .
                $border . "\n\n");
    }
};

# main
App::Feed2Txt->new(
    feed_urls => [ @ARGV ],
)->run();
