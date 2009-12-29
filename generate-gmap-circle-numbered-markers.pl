#!/usr/bin/env perl -w
use strict;
use warnings;
use 5.010;

use Imager;


my $white = Imager::Color->new(255, 255, 255);
my $font = Imager::Font->new(file=> "/Users/gugod/Library/Fonts/DroidSansMono.ttf");
my $bg = Imager::Color->new(156, 176, 175);

sub generate_circle_of {
    my $x = shift;
    my $img = Imager->new(xsize => 32, ysize => 32, channels => 4);

    $img->circle(color => $bg,    r => 15, x => 16, y => 16, filled => 1, aa => 1);
    $img->circle(color => $white, r => 14, x => 16, y => 16, aa => 1);
    $img->circle(color => $bg,    r => 12, x => 16, y => 16, filled => 1, aa => 1);

    $img->align_string(
        x => 16, y => 15,
        halign => 'center',
        valign => 'center',
        string => $x,
        font => $font,
        size => ($x >= 100 ? 11 : 14),
        aa => 1,
        color => 'white'
    );

    $img->write(file => "$x.png");
    say "$x.png generated";
}

generate_circle_of($_) for map { 5* $_ } (0..40);
