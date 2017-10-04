#!/usr/bin/env perl
use v5.18;

use Net::Twitter;
use YAML;
use Sereal::Encoder;
use DateTime;
use DateTime::Format::Strptime;

my %args = @ARGV;
my $config_file = $args{'-c'} or die;
my $output_dir  = $args{'-o'} or die;

my $config = YAML::LoadFile($config_file);

my $t = Net::Twitter->new( traits   => ['API::RESTv1_1'], %$config );

my $statuses = $t->home_timeline({ count => 200 });
my @keep;
my %users;
my %seen;

my $datetime_parser = DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y');

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

my $srl = Sereal::Encoder->new();
my $ts = time;
open my $fh, ">", "${output_dir}/twitter-timeline-${ts}.srl";
print $fh "". $srl->encode(\@keep);
close($fh);

open $fh, ">", "${output_dir}/twitter-timeline-users-${ts}.srl";
print $fh "". $srl->encode(\%users);
close($fh);
