#!/usr/bin/env perl
use v5.26;
use Encode qw(decode_utf8 encode_utf8);
use Getopt::Long qw(GetOptions);
use Mojo::UserAgent;
use XML::Loy;
use File::Slurp qw(read_file);

sub fetch {
    my ($url) = @_;
    my $body;
    if ($url =~ /^file:\/\/(.+)$/) {
        my $filename = $1;
        $body = decode_utf8 read_file($filename);
    } else {
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->get($url);
        unless ($tx->res->is_success) {
            say STDERR "Failed to fetch: $url";
            return;
        }
        $body = decode_utf8 $tx->res->body;
    }

    return $body;
}

sub fetch_and_print {
    my ($url, $opts) = @_;

    my $body = fetch($url);
    my $xml = XML::Loy->new($body);

    my @rows;
    # rss
    $xml->find("item")->each(
        sub {
            my $el = $_;
            push @rows, {
                title => $el->at("title")->text,
                link  => $el->at("link")->text,
            };
        }
    );

    # atom
    $xml->find("entry")->each(
        sub {
            my $el = $_;
            my %o = (
                title => $el->at("title") // '',
                link  => $el->at("link")->attr("href") // '',
            );
            for my $k (keys %o) {
                $o{$k} = $o{$k}->text if ref($o{$k});
                $o{$k} =~ s/\s+/ /g;
            }
            push @rows, \%o;
        }
    );

    for my $row (@rows) {
        say encode_utf8( join "\t", @$row{@{$opts->{fields}}} );
    }
}

## main
my %opts;
GetOptions(
    \%opts,
    "fields=s",
);
if ($opts{fields}) {
    $opts{fields} = [split /,/ => $opts{fields}];
} else {
    $opts{fields} = [ "link", "title" ];
}

for my $feed_url (@ARGV) {
    fetch_and_print($feed_url, \%opts);
}
