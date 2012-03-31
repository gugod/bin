#!/usr/bin/env perl
use v5.14;

use HTTP::Proxy;
use HTTP::Proxy::BodyFilter::simple;
use HTTP::Proxy::BodyFilter::complete;
use HTTP::Proxy::HeaderFilter::simple;
use LWP::UserAgent::Cached;
use Web::Query;
use YAML;
use AnyEvent;
use AnyEvent::MPRPC;
use Try::Tiny;

my $mprpc_client;

if (0 == fork) {
    my $server = mprpc_server '127.0.0.1', '4423';
    $server->reg_cb(
        fetch => sub {
            my ($uri) = @_;

            try {
                my $a = LWP::UserAgent::Cached->new(cache_dir => '/tmp/prefetching-proxy-cache');
                $a->timeout(6);
                $a->get($uri);
                return "FETCHED $uri";
            }
            catch {
                warn "Caught Error: $_\n";
            }
        }
    );

    AnyEvent->condvar->recv;
    exit;
}

$mprpc_client = mprpc_client '127.0.0.1', '4423';

mkdir('/tmp/prefetching-proxy-cache');
my $ua = LWP::UserAgent::Cached->new(cache_dir => '/tmp/prefetching-proxy-cache', timeout => 60);

my $proxy = HTTP::Proxy->new(
    port => 3128,
    keep_alive  => 1,
    agent => $ua
);

$proxy->push_filter(
    method  => 'GET',
    mime    => 'text/html',
    response => HTTP::Proxy::BodyFilter::complete->new,
    response => HTTP::Proxy::BodyFilter::simple->new(
        sub {
            my ($self, $dataref, $message, $protocol, $buffer) = @_;

            return unless $message->code == 200;
            return unless $message->content_is_html;
            return unless ref($dataref) eq 'SCALAR';

            my $q = Web::Query->new_from_html($$dataref);

            my $request_uri = $message->request->uri;

            $q->find("a[href]")->each(
                sub {
                    my $href = $_->attr("href");
                    return unless $href =~ m{^(/|http://)};

                    my $u = URI->new($href)->abs($request_uri);

                    $mprpc_client->call('fetch' => "$u")->cb(
                        sub {
                            say $_[0]->recv;
                        }
                    );
                }
            );
        }
    )
);

$proxy->start;
