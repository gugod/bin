#!/usr/bin/env perl
use v5.18;
use Imager;

@ARGV == 2 or die;
my ($input, $output) = @ARGV;

my $img = Imager->new(file => $input) or die Imager->errstr;
$img = $img->to_paletted({ make_colors => "webmap" });

$img->write(file => $output) or die $img->errstr;
