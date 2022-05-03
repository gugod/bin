#!/usr/bin/env perl
use v5.32;
use warnings;

use Regexp::Common qw< URI Email::Address >;

sub usage {
    print q{

Usage:

    re <object>

The "object" could be one of:

    email    one email address
    uri      one uri of all schemes

};
}

sub MAIN {
    my ($what) = @_;
    $what or die usage();

    my %re_of = (
        "email" => $RE{Email}{Address},
        "uri"   => $RE{URI},
    );

    $re_of{$what} or die "Unknown object: $what\n";

    say $re_of{$what};
}

MAIN(@ARGV);
