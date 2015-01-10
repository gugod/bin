#!/usr/bin/env perl
use v5.14;
use strict;
use Imager;

@ARGV == 3 or die <<"USAGE";
$0 - <image_1> <image_2> <image_output>
USAGE

my $output = pop(@ARGV);
my @imgs = map { Imager->new(file => $_) } @ARGV;

my $diff = $imgs[0]->difference(other => $imgs[1]);

$diff->write(file => $output);
