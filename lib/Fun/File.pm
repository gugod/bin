package Fun::File;
use v5.18;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(srl_slurp srl_spew);

use Sereal::Decoder;
use Sereal::Encoder;

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
