#!/usr/bin/env perl

use HTTP::Proxy;
use HTTP::Recorder;

my $proxy = HTTP::Proxy->new();
$proxy->port(3128);
$proxy->max_connections(20);

# create a new HTTP::Recorder object
my $agent = HTTP::Recorder->new;

# set the log file (optional)
$agent->file("/tmp/http-recorder.log");

# set HTTP::Recorder as the agent for the proxy
$proxy->agent( $agent );

# start the proxy
$proxy->start();

1;
