#!/usr/bin/env perl
use v5.28;

use Mojo::UserAgent;

binmode STDOUT, ":utf8";

my %visited;
my @indices = ('https://readmoo.com');

my $ua = Mojo::UserAgent->new;
my $res;

while(@indices) {
    my $url = pop(@indices);
    next if $visited{$url};

    say STDERR ">>> OPEN $url";

    $res = $ua->get($url)->result;
    $res->dom->find("a[href*=book/]")->each(
        sub {
            my $title = $_->all_text() or return;
            my $link = $_->attr("href");

            return unless ($link =~ m{//readmoo\.com/book/[0-9]+$}) && (not $visited{$link});

            $visited{$link} = 1;
            say $link . "\t" . $title;
        }
    );

    $res->dom->find("a[href*=category/]")->each(
        sub {
            my $link = $_->attr("href");
            my $link_no_params = $link =~ s/\?.+$//r;
            return unless ($link_no_params =~ m{/category/[0-9]+$}) && (not $visited{$link_no_params});
            $visited{$link_no_params} = 1;

            # Not a mistake. Links are deduped by their param-less version but visited as-is.
            push @indices, $link;
        }
    );

    $visited{$url} = 1;
}
