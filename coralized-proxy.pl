#!/usr/bin/env perl

sub is_blocked {
    my $host = shift;
    if ($host =~ m/(?:
                       doubleclick\.net |
                       (?: untang|sohu)\.com
                   )$/x) {
        print "$host Fnord\n";
        return 1;
    }
}

sub should_not_proxy {
    my $host = shift;
    $host =~ /(?:
                  \.nyud\.net |
                  ( google-analytics
                  | google
                  | fooooo
                  | youtube
                  | googlesyndication
                  | flickr
                  | mac
                  )\.com
              )$/x;
}

use HTTP::Proxy;
use HTTP::Proxy::HeaderFilter::simple;

my $verbose = 0;
my $proxy = HTTP::Proxy->new(
    port => 3128,
    keep_alive => 0,
    max_clients => 100
);

$proxy->push_filter(
    request =>HTTP::Proxy::HeaderFilter::simple->new(
        sub {
            my ( $self, $headers, $message ) = @_;
            my $host = $message->uri()->host();

            if (is_blocked($host)) {
                print "!!! " . $message->uri . "\n" if $verbose;

                $message->uri("file:///dev/null");
                return;
            }
            unless ($message->uri()->port() != 80 || should_not_proxy($host)) {
                $host .= ".nyud.net";
                $message->uri()->host($host);
                $headers->header(Host => $host);

                print "==> " . $message->uri()->as_string . "\n" if $verbose;
            }

        }
    ),
    response => HTTP::Proxy::HeaderFilter::simple->new(
        sub {
            my ($self, $headers, $message) = @_;
            if ($message->code == 302) {
                my $location = $headers->header('Location');
                $location =~ s/\.nyud\.net//;
                $headers->header(Location => $location);
            }
        }
    )
);
$proxy->start;
