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
    return ref($o) ? Sereal::Encoder->new({ compress => Sereal::Encoder::SRL_ZSTD() })->encode($o) : Sereal::Decoder->new()->decode($o);
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

1;
