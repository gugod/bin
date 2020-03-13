#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;

use GIS::Distance;
use File::Next;
use Getopt::Long;
use Image::ExifTool;
use Image::ExifTool::Location;

sub usage {
    return <<USAGE;

Example: Find jpeg files store under 2 folders with Geo tags that is with 10kms from [Erlin Butokuden][1]

    file-jpg-gps-grep --ll 23.8997913,120.3691942 --disntance 10 /data/main/Pictures /data/backup/Pictures

[1]: https://goo.gl/maps/genakeXbVdaK8oDb7

Both of these parameters are necessary.

    --ll          lat,long -- that is, 2 decimals with a comma in between.
                  This is the usual format found in valious web-based maps.

    --distance    Decimal numbers. In Kilometres.

USAGE
}

sub main {
    my ($opts, $args) = @_;
    my (@paths) = @$args;

    die usage() unless @paths && $opts->{ll} && $opts->{distance};

    my $distance = $opts->{distance};
    my ($lat, $long) = split(',', $opts->{ll}, 2);
    die usage() unless defined($lat) && defined($long);

    my $iter = File::Next::files(+{ file_filter => sub { /\.jpg\z/i } }, @paths );
    my $gis = GIS::Distance->new();

    while (my $file = $iter->()) {
        my $exif = Image::ExifTool->new;
        $exif->ExtractInfo($file);
        next unless $exif->HasLocation;

        my ($image_lat, $image_long) = $exif->GetLocation;
        my $d = $gis->distance($lat, $long, $image_lat, $image_long)->kilometre;

        # say "$file\t$d";

        next unless $d < $distance;

        say "$file\t$d";
    }
}

my %opts;
GetOptions(
    \%opts,
    'll=s',
    'distance=n',
 );
main(\%opts, [@ARGV]);
