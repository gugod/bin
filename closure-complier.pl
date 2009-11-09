#!/usr/bin/env perl
#
# Usages:
#
#    closure-complier.pl < file1.js file2.js file3.js ... > out.js
#
#
use strict;
use warnings;

use LWP::UserAgent;

local $\ = "\n";
local $/ = undef;

my $code = <>;

my $ua = LWP::UserAgent->new;

my $r = $ua->post("http://closure-compiler.appspot.com/compile", {
    js_code           => $code,
    compilation_level => "ADVANCED_OPTIMIZATIONS",
    output_info       => "compiled_code",
    output_format     => "text"
});

if ($r->is_success) {
    print $r->decoded_content;
}
else {
    print "Error";
}
