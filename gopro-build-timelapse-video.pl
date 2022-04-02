#!/usr/bin/env perl
use v5.18;
use warnings;

use Getopt::Long qw(GetOptions);

use File::Basename 'basename';
use List::MoreUtils 'uniq';

my %args;
GetOptions(
    \%args,
    "i=s"
);

my $output_dir_base = "/tmp/gopro-timelapse";
mkdir($output_dir_base) unless -d $output_dir_base;

my $input_dir = $args{i};

my @pic = <${input_dir}/*GOPRO/G*.JPG>;
my %pic_groups;
for my $f (@pic) {
    my $g = substr(basename($f), 0, 4);
    push @{$pic_groups{$g}}, $f;
}

for my $g (keys %pic_groups) {
    my @files = sort { $a cmp $b } @{$pic_groups{$g}};

    my $output_dir = $output_dir_base . "/$g";
    mkdir($output_dir) unless -d $output_dir;

    my $counter = 0;
    for my $f (@files) {
        $counter++;
        my $f2 = sprintf("%s/pic-%05d.jpg", $output_dir, $counter);
        symlink($f, $f2);
    }

    say "ffmpeg -i /tmp/gopro-timelapse/$g/pic-\%05d.jpg -r 30 -s 1920x1080 -b:v 0 $g.1080p.m4v";
}

__END__

#!/bin/sh
for p in /tmp/gopro-timelapse/*
do
    name=$(basename $p)
    ffmpeg -i /tmp/gopro-timelapse/${name}/pic-%05d.jpg -r 30 -s 1920x1080 -c:v libvpx-vp9 -crf 30 -b:v 0 ${name}.1080p.webm
done
