#!/usr/bin/env perl
use common::sense;
use Imager qw(:handy);

sub random_from {
    return $_[ int rand $#_ ]
}

sub random_color {
    return [map { int rand(255) } 1..4]
}

sub random_background {
    my ($xsize, $ysize) = @_;

    my $image = Imager->new(xsize => $xsize, ysize => $ysize, channels => 3);
    # Background
    $image->box(filled => 1, color => random_color);
    $image->filter(type => "gradgen",
                   xo => [map { int rand($xsize) } 1..2],
                   yo => [map { int rand($ysize) } 1..2],
                   colors => [ map { random_color } 1..2 ]);

    $image->filter(type => "noise",    subtype => 0, amount => 10);
    $image->filter(type => "gaussian", stddev  => 5);

    return $image;
}

sub new_layer {
    my ($xsize, $ysize, $cb) = @_;
    my $layer = Imager->new(xsize => $xsize, ysize => $ysize, channels => 4);
    $cb->($layer);
    return $layer;
}

sub random_pic {
    my ($xsize, $ysize) = @_;
    # my $image = Imager->new(xsize => $xsize, ysize => $ysize);
    # my $background = random_background($xsize, $ysize);
    my $image = random_background($xsize, $ysize);

    # Big Blur Circles
    new_layer(
        $xsize, $ysize,
        sub {
            my ($layer) = @_;
            my $layer = Imager->new(xsize => $xsize, ysize => $ysize, channels => 4);
            $layer->filter(type => "noise", subtype => 0, amout => 20);
            for my $size (map { 200 + $_ } 1..20) {
                my ($x, $y) = (int(rand($xsize)), int(rand($ysize)));
                $layer->circle(fill => { solid   => [255, 255, 255, 30],  combine => "multiply" },
                               x => $x, y => $y, r => $size);
            }
            $layer->filter(type => "gaussian", stddev => 10);
            $image->compose(src => $layer, tx => 0, ty => 0, combine => 'add');
        }
    );

    # Big Blur Boxes
    new_layer(
        $xsize, $ysize,
        sub {
            my ($layer) = @_;
            $layer->filter(type => "noise", subtype => 0, amout => 20);
            for my $size (map { 200 + $_ } 1..20) {
                my ($x, $y) = (int(rand($xsize)), int(rand($ysize)));
                $layer->box(fill => { solid   => [255, 255, 255, 30],  combine => "multiply" },
                            xmin => $x, ymin => $y,
                            xmax => $x + $size, ymax => $y + $size);
            }
            $layer->filter(type => "mosaic", size => 30);
            $image->compose(src => $layer, tx => 0, ty => 0, combine => 'add');
        }
    );

    # Small Sharp Circles
    for my $size (map { 2 * $_ + 45 } 1..20) {
        my ($x, $y) = (int(rand($xsize - 2 * $size)), int(rand($ysize - 2 * $size)));
        $image->circle(fill => { solid => [255, 255, 255, 50], combine => "add" }, x => $x, y => $y, r => $size + 5);
        $image->circle(fill => { solid => [100, 100, 100, 50], combine => "subtract" }, x => $x, y => $y, r => $size);
    }

    return $image;
}

for(1..3) {
    srand($_);
    my $i = random_pic(1680, 1050);
    my $fn = "$ENV{HOME}/tmp/pic_$_.png";
    $i->write(file => $fn) or die $i->errstr;
    say "$fn created";
}

