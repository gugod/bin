#!/usr/bin/env perl
use common::sense;
use CSS::LESSp;
#http://search.cpan.org/~drinchev/CSS-LESSp-0.03/lib/CSS/LESSp.pm

my $buffer;
my $file = shift @ARGV || die "Usage: $0 <style.less>\n";

local $/ = undef;

open(IN, $file);
$buffer = <IN>;

my @css = CSS::LESSp->parse($buffer);

my $outfile = $file;
$outfile =~ s/\.less$/.css/;

open OUT, ">", $outfile;
print OUT join("", @css);
