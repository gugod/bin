#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;

use Net::Twitter;
use YAML;
use Getopt::Long 'GetOptions';

use FindBin;
use lib $FindBin::Bin . "/lib";
use Fun::File qw(srl_slurp srl_spew);

my %opts;
GetOptions(
    \%opts,
    "c=s",
    "o=s",
);

my @search_terms = @ARGV;
my $config_file = $opts{c} or die;
my $output_dir  = $opts{o} or die;

my $config = YAML::LoadFile($config_file);

my $t = Net::Twitter->new( traits   => ['API::RESTv1_1'], %$config );

binmode STDOUT, ":utf8";

for (@search_terms) {
    utf8::decode($_);

    my $res = $t->search({ q => $_, count => 100 });
    my $ts = time;
    srl_spew("${output_dir}/twitter-raw-search-${ts}.srl", $res);
    say $_;
    sleep 1;
}
