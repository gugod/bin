#!/usr/bin/env perl
use v5.18;
use warnings;

use Convert::Moji;
use Data::HanConvert::cn2tw;
use Data::HanConvert::cn2tw_characters;

sub s2t {
    state $s2t_converter = Convert::Moji->new([
        table => {
            %$Data::HanConvert::cn2tw,
            %$Data::HanConvert::cn2tw_characters
        }
    ]);


    return $s2t_converter->convert( $_[0] );
};

binmode STDIN,  ":utf8";
binmode STDOUT, ":utf8";

while (<>) {
    print s2t($_);
}
