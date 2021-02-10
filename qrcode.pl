#!/usr/bin/env perl
use v5.14;
use warnings;
use Getopt::Long 'GetOptions';
use Imager::QRCode;

my %opts;
GetOptions(
    \%opts,
    "o=s",
);
my $output;
if ($opts{o}) {
    if (-f $opts{o}) {
        die "Output $opts{o} already exist\n";
    }
    $output = $opts{o};
} else {
    $output = "qrcode.png";
    my $c = 1;
    while (-f $output) {
        $c += 1;
        $output = "qrcode_" . $c . ".png";
    }
}

my $text;
if (-p STDIN) {
    $text = do { local $/; <STDIN> };
} else {
    $text = shift;
}
$text or die 'text ?';

my $qrcode = Imager::QRCode->new();

my $img = $qrcode->plot($text);

$img->write( file => $output ) or die Imager->errstr;

my $prog = ($^O eq 'linux') ? 'xdg-open' : 'open';

system($prog, $output);
