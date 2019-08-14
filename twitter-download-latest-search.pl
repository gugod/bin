#!/usr/bin/env perl
use v5.18;
use warnings;

use Net::Twitter;
use YAML;
use Getopt::Long 'GetOptions';

use FindBin;
use lib $FindBin::Bin . "/lib";
use Fun::File qw(srl slurp spew);

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
    spew("${output_dir}/twitter-raw-search-${ts}.srl", srl($res));
    say $_;
    sleep 1;
}

my ($status, $user, $seen) = ([],{},{});

my @materials = sort { $a cmp $b } glob($output_dir . "/twitter-raw-*.srl");

for my $f (@materials) {
    say $f;
    my $res = srl(slurp($f));

    for my $tweet (grep { ! exists $seen->{$_->{id}} } @{$res->{statuses}}) {
        my $o = delete $tweet->{user};
        $user->{ $o->{id}  } //= $o;
        $tweet->{'user.id'} = $o->{id};
        $seen->{ $tweet->{id} } = 1;
        push @$status, $tweet;
    }
}

my $ts = time();
my $output_status = "${output_dir}/twitter-status-${ts}.srl";
my $output_user   = "${output_dir}/twitter-user-${ts}.srl";

spew($output_status, srl($status));
spew($output_user, srl($user));

unlink(@materials);
