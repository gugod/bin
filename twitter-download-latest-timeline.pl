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

my $statuses = $t->home_timeline({ count => 400 });
my @keep;

my $datetime_parser = DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y');

my @fields = qw(text lang id in_reply_to_status_id);
for (@$statuses) {
    my %s = (
        'user.id' => $_->{user}{id},
        'created_at' => $datetime_parser->parse_datetime($_->{created_at})->epoch
    );
    @s{@fields} = @{$_}{@fields};
    push @keep, \%s;
}

my $srl = Sereal::Encoder->new();
my $ts = time;
open my $fh, ">", "${output_dir}/twitter-timeline-${ts}.srl";
print $fh "". $srl->encode(\@keep);
close($fh);
