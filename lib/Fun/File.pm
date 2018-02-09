package Fun::File;
use v5.18;
use strict;
use warnings;

use Exporter 'import';
use Module::Functions;
our @EXPORT_OK = get_public_functions();

use Sereal::Decoder;
use Sereal::Encoder;

sub srl {
    my $o = shift;
    return ref($o) ? Sereal::Encoder->new()->encode($o) : Sereal::Decoder->new()->decode($o);
}

sub spew {
    my ($file, $content) = @_;
    open(my $fh, ">", $file) or die $!;
    print $fh $content;
    close($fh);
}

sub slurp {
    my ($file) = @_;
    my $d = do {
        open(my $fh, "<", $file) or die $!;
        local $/ = undef;
        <$fh>;
    };
    return $d;
}

sub srl_slurp {
    my ($file) = @_;
    my $d = do {
        open(my $fh, "<", $file) or die $!;
        local $/ = undef;
        <$fh>;
    };
    my $u;
    my $srl_decoder = Sereal::Decoder->new;
    if ($srl_decoder->looks_like_sereal($d)) {
        $u = $srl_decoder->decode($d);
    }
    return $u;
}

sub srl_spew {
    my ($file, $o) = @_;
    my $srl_encoder = Sereal::Encoder->new;
    open(my $fh, ">", $file) or die $!;
    print $fh $srl_encoder->encode($o);
    close($fh);
}

1;
