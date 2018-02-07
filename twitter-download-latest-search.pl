#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;

use Net::Twitter;
use YAML;
use Sereal::Encoder;
use DateTime;
use DateTime::Format::Strptime;

use FindBin;
use lib $FindBin::Bin . "/lib";
use Fun::File qw(srl_slurp srl_spew);

my %args = @ARGV;
my $config_file = $args{'-c'} or die;
my $output_dir  = $args{'-o'} or die;

my $config = YAML::LoadFile($config_file);

my $t = Net::Twitter->new( traits   => ['API::RESTv1_1'], %$config );

use utf8;
binmode STDOUT, ":utf8";

my @search_terms = (
    "台灣 地震",
    "台湾 地震",
    "taiwan earthquake",
    "taiwan tremblement de terre",
    "taiwan séisme",
    "aardbeving taiwan",
    "землетрясение Тайване",
);

for (@search_terms) {
    my $res = $t->search({ q => $_, count => 100 });
    my $ts = time;
    srl_spew("${output_dir}/twitter-raw-search-${ts}.srl", $res);
    say $_;
    sleep 1;
}
