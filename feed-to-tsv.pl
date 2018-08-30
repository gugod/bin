#!/usr/bin/env perl
use v5.26;
use Encode qw(decode_utf8 encode_utf8);
use Getopt::Long qw(GetOptions);
use Mojo::UserAgent;
use XML::Loy;

sub fetch_and_print {
    my ($url) = @_;
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get($url);

    unless ($tx->res->is_success) {
        say STDERR "Failed to fetch: $url";
        return;
    }

    my @row;
    my $body = decode_utf8 $tx->res->body;
    my $xml = XML::Loy->new($body);

    # rss
    $xml->find("item")->each(
        sub {
            my $el = $_;
            my @fields = (
                '__rss__',
                $el->at("title")->text,
                $el->at("link")->text,
            );
            say join "\t", @fields;
        }
    );

    # atom
    $xml->find("entry")->each(
        sub {
            my $el = $_;
            my @fields = map {
                s/\s+/ /r;
            } map {
                ref($_) ? $_->text : $_
            } (
                $el->at("author name") // '',
                $el->at("title") // '',
                $el->at("link")->attr("href") // '',
            );
            say encode_utf8 join("\t", @fields);
            # say $fields[0];
        }
    );
}

## main
my %opts;
GetOptions(
    \%opts,
    "fields=s",
);

for my $feed_url (@ARGV) {
    fetch_and_print($feed_url);
}
