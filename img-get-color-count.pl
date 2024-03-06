#!/usr/bin/env perl
use strict;
use warnings;
use Imager;

for my $file ( @ARGV ) {
    my $img = Imager->new;
    $img->read( file => $file ) or die $img->errstr;
    print $file, "\t", $img->getcolorcount, "\n";
}
