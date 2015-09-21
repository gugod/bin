#!/usr/bin/env perl
use v5.18;

use Feed::Pipe;

use XML::Feed;
use URI;

my @feeds = map { chomp; XML::Feed->parse(URI->new($_)) } <>;

print Feed::Pipe->cat(@feeds)->as_xml;
