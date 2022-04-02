#!/usr/bin/env raku

sub MAIN (Str $filename, Str $needle) {
    my $very-large-file = $filename.IO.open;

    my $chunk-offset = 0;
    my $chunk-size = 65536;
    my $pos;

    my $buf = "";
    my $buf-offset = 0;

    until $pos.defined {
        my $chunk = $very-large-file.readchars( $chunk-size );
        $chunk-offset += $chunk-size;

        $buf = $buf ~ $chunk;

        $pos = $buf.index($needle);

        unless $pos.defined {
            if (my $p = $buf.rindex( $needle.substr(0,1) )).defined {
                $buf = $buf.substr($p);
                $buf-offset += $p;
            } else {
                $buf = "";
                $buf-offset = $chunk-offset;
            }
        }
    }
    $very-large-file.close;

    if $pos.defined {
        say $buf-offset + $pos;
    } else {
        say "Not found";
    }
}
