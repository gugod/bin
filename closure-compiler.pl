#!/usr/bin/env perl
#
# Usages:
#
#    closure-complier.pl < file1.js file2.js file3.js ... > out.js
#
# The defalut optimization level is "Simple", and can be altered with
# the following argument flags:
#
#    -w   Use "Whitespace Only" optimization
#    -a   Use "Advadced" optimization
#

use common::sense;
use LWP::UserAgent;
use Getopt::Std;

my %opts;
getopts("sa", \%opts);

my $level = "SIMPLE_OPTIMIZATIONS";
$level = "WHITESPACE_ONLY"        if $opts{w};
$level = "ADVANCED_OPTIMIZATIONS" if $opts{a};

local $\ = "\n";
local $/ = undef;

my $code = <>;

my $ua = LWP::UserAgent->new;

my $r = $ua->post("http://closure-compiler.appspot.com/compile", {
    js_code           => $code,
    compilation_level => $level,
    output_info       => "compiled_code",
    output_format     => "text"
});

if ($r->is_success) {
    print $r->decoded_content;
}
else {
    print "/* Error */";
}
