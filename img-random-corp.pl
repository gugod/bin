#!/usr/bin/env perl
use v5.18;
use warnings;
use Imager;

my $base_img = shift(@ARGV);
my @spec = @ARGV;

my $img = Imager->new(file => $base_img);

my $img_width = $img->getwidth;
my $img_height = $img->getheight;

for my $spec (@spec) {
    my ($w, $h, $copies) = $spec =~ m/\A ([0-9]+)x([0-9]+)(?:,([0-9]+)) \z/x;
    $copies ||= 1;

    unless ($w && $h && $copies) {
        warn "Weird spec: $spec";
        next;
    }

    for (my $i = 0; $i < $copies; $i++) {
        my $x = rand() * ( $img_width - $w );
        my $y = rand() * ( $img_height - $h );

        my $copy = $img->crop( left => $x, top => $y, width => $w, height => $h );
        $copy->write(file => "rand-crop-${w}x${h}-${i}.png");
    }
};

