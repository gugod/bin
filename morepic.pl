#!/usr/bin/env perl
package main;
use common::sense;
use Acme::DreamyImage;

my ($width, $height) = @ARGV;
$width  = 512    unless $width;
$height = $width unless $height;

while(<STDIN>) {
    chomp($_);
    my $fn = "$ENV{HOME}/tmp/pic_$_.png";

    my $pic = Acme::DreamyImage->new(seed => $_, width => $width, height => $height);
    $pic->write(file => $fn);
    say "$fn created";
}
