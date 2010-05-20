#!/usr/bin/env perl
package Morepic;
use common::sense;
use Object::Tiny qw(seed width height);
use Imager qw(:handy);
use self;

sub write {
    my $image = $self->random_image;
    $image->write(@args) or die $image->errstr;
    return $self;
}

sub random {
    my ($upper_bound) = @args;
    $upper_bound ||= 1;

    $self->{pos} = 0 unless defined($self->{pos});
    my $value = substr($self->{seed}, $self->{pos}, 1);
    $self->{pos} += 1;
    $self->{pos} = 0 if $self->{pos} >= length($self->{seed});
    return int(hex($value) / 15 * $upper_bound);
}

sub random_color {
    return [map { $self->random(255) } 1..4]
}

sub random_background {
    my $image = Imager->new(xsize => $self->width, ysize => $self->height, channels => 3);
    $image->box(filled => 1, color => [255, 255, 255]);
    $image->filter(type => "gradgen",
                   xo => [map { $self->random($self->width)  } 1..2],
                   yo => [map { $self->random($self->height) } 1..2],
                   colors => [ map { $self->random_color } 1..2 ]);

    $image->filter(type => "noise",    subtype => 0, amount => $self->random(10));
    $image->filter(type => "gaussian", stddev  => $self->random( ($self->width + $self->height) / 2 * 0.03 ));

    return $image;
}

sub new_layer {
    my ($xsize, $ysize, $cb) = @_;
    my $layer = Imager->new(xsize => $xsize, ysize => $ysize, channels => 4);
    $cb->($layer);
    return $layer;
}

sub random_image {
    my $image = $self->random_background;
    my $xsize = $self->width;
    my $ysize = $self->height;

    # Big Blur Circles
    new_layer(
        $xsize, $ysize,
        sub {
            my ($layer) = @_;
            my $layer = Imager->new(xsize => $xsize, ysize => $ysize, channels => 4);
            $layer->filter(type => "noise", subtype => 0, amout => 20);
            for my $size (map { ($xsize + $ysize) / 16 + $_ } 1..20) {
                my ($x, $y) = ($self->random($xsize), $self->random($ysize));
                $layer->circle(fill => { solid   => [255, 255, 255, $self->random(30) + 10],  combine => "add" }, x => $x, y => $y, r => $size);
            }
            $layer->filter(type => "gaussian", stddev => $self->random(30));

            $image->compose(src => $layer, tx => 0, ty => 0, combine => 'add');
        }
    );

    # Big Blur Boxes
    new_layer(
        $xsize, $ysize,
        sub {
            my ($layer) = @_;
            for my $size (map {  ($xsize + $ysize) / 16 + $_ } 1..20) {
                my ($x, $y) = ($self->random($xsize), $self->random($ysize));
                $layer->box(fill => { solid   => [255, 255, 255, $self->random(30) + 10],  combine => "add" },
                            xmin => $x, ymin => $y,
                            xmax => $x + $size, ymax => $y + $size);
            }
            $layer->filter(type => "noise", amount => $self->random(($xsize + $ysize) /2 * 0.03 ), subtype => 1);
            $layer->filter(type => "gaussian", stddev => $self->random(30));

            $image->compose(src => $layer, tx => 0, ty => 0, combine => 'add');
        }
    );

    # Small Sharp Circles
    for (1..10+$self->random(20)) {
        my $size = $self->random( ($xsize + $ysize) / 2 / 16);
        my ($x, $y) = ($self->random($xsize), $self->random($ysize));
        my $opacity = $self->random(30) + 10;
        $image->circle(fill => { solid => [255, 255, 255, $opacity], combine => "add" },  x => $x, y => $y, r => $size);
    }

    return $image;
}

package main;

my ($width, $height) = @ARGV;
$width  = 512    unless $width;
$height = $width unless $height;

while(<STDIN>) {
    chomp($_);
    my $fn = "$ENV{HOME}/tmp/pic_$_.png";

    my $pic = Morepic->new(seed => $_, width => $width, height => $height);
    $pic->write(file => $fn);
    say "$fn created";
}
