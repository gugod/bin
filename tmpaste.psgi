#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;

use HTML::Escape qw(escape_html);
use Plack::Request;

my $app = sub {
    my ($env) = @_;
    my $req = Plack::Request->new($env);
    my $res;

    state $pasted = '';

    if ($req->method eq 'GET') {
        # Render pasted content

        my $pasted_escaped = escape_html($pasted);
        $res = $req->new_response(200);
        $res->body(
            '<!DOCTYPE html>' .
            '<html>' .
            '<head><meta charset="UTF-8"> </head><body>' .
            '<form method="POST" action="/"><p><textarea autofocus name="p"></textarea><p><p><input type="submit"/></p></form>' .
            '<pre>' . $pasted_escaped . '</pre>' .
            '</body></html>'
        );
    } elsif ($req->method eq 'POST') {
        $pasted = $req->parameters->get("p");

        $res = $req->new_response();
        $res->redirect("/");
    }

    return $res->finalize;
};

$app;
