#!/usr/bin/env raku

sub MAIN (Str $needle) {
    my $pi-file = (%*ENV{"HOME"} ~ "/var/pi-billion.txt").IO.open;
    my $chunk-offset = 0;
    my $chunk-size = 65536;
    my $pos;

    my $pi-buf = "";
    my $pi-buf-offset = 0;

    until $pos.defined {
        my $chunk = $pi-file.readchars( $chunk-size );
        $chunk-offset += $chunk-size;

        $pi-buf = $pi-buf ~ $chunk;

        $pos = $pi-buf.index($needle);

        unless $pos.defined {
            if (my $p = $pi-buf.rindex( $needle.substr(0,1) )).defined {
                $pi-buf = $pi-buf.substr($p);
                $pi-buf-offset += $p;
            } else {
                $pi-buf = "";
                $pi-buf-offset = $chunk-offset;
            }
        }
    }

    $pi-file.close;

    if $pos.defined {
        say $pi-buf-offset + $pos;
    }
}
