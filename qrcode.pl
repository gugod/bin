#!/usr/bin/env perl
use v5.14;
use warnings;
use Getopt::Long 'GetOptions';
use File::Temp 'tempfile';
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
}

my %progs = (
    'linux' => 'xdg-open',
    'darwin' => 'open'
);

my $prog = $progs{$^O};

unless ($prog || $opts{o}) {
    die "It looks like there is no way to open the output.";
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

my $fh;

if ($output) {
    open( $fh, '>', $output ) or die $!;
} else {
    ($fh, $output) = tempfile( "qrcode_XXXXXXXX", TMPDIR => 1, SUFFIX => '.png' );
}

$img->write( fh => $fh, type => "png" ) or die Imager->errstr;
close($fh);

if ($prog) {
    system($prog, $output);
    sleep(1);
    unlink($output);
}
