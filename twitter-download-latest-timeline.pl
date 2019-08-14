#!/usr/bin/env perl
use v5.18;
use warnings;

use Net::Twitter;
use YAML;

use FindBin;
use lib $FindBin::Bin . "/lib";
use Fun::File qw(srl spew);

my %args = @ARGV;
my $config_file = $args{'-c'} or die;
my $output_dir  = $args{'-o'} or die;

my $config = YAML::LoadFile($config_file);

my $t = Net::Twitter->new( traits   => ['API::RESTv1_1'], %$config );

my $statuses = $t->home_timeline({ count => 200 });
my @keep;
my %users;
my %seen;

my @source;
push @source, @$statuses;

my @fields = qw(text lang id in_reply_to_status_id);
while (my $tweet = shift @source) {
    next if $seen{$tweet->{id}}++;

    if ($tweet->{retweeted_status}) {
        push @source, $tweet->{retweeted_status};
        next;
    }

    my $user = delete $tweet->{user};

    $tweet->{"user.id"} = $user->{id};
    $users{ $user->{id} } //= $user;

    push @keep, $tweet;
}

my $ts = time;
spew("${output_dir}/twitter-status-${ts}.srl", srl(\@keep));
spew("${output_dir}/twitter-user-${ts}.srl", srl(\%users));
