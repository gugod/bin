#!/usr/bin/env perl
use v5.18;
use warnings;

use FindBin;
use lib $FindBin::Bin . "/lib";
use Fun::Web qw(url_remove_tracking_params url_unshorten);

while(<>) {
    chomp;
    my $url = $_;
    next unless URI->new($url)->path;
    my $url2 = url_remove_tracking_params( url_unshorten($url) );
    say $url2 if URI->new($url2)->path;
}
