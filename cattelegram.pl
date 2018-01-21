#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;
use JSON::PP;
use WWW::Telegram::BotAPI;
use Getopt::Long qw(GetOptions);
use File::Slurp qw(write_file);
use File::Spec::Functions qw(catfile);

my %opts;
GetOptions(
    \%opts,
    "chat-id=s",
    "token=s",
    "o=s",
);

my $output_directory;
if (exists $opts{o}) {
    unless (-d $opts{o}) {
        die qq{Please ensure that the output dir (argument "-o <DIR>") is a directory\n};
    }
    $output_directory = $opts{o};
}

my $JSON = JSON::PP->new->utf8->canonical;
my $bot = WWW::Telegram::BotAPI->new( token => $opts{token} );
my $res = $bot->api_request('getMe');

$res = $bot->api_request(
    'getUpdates',
    { timeout => 60 },
);

if ($res && $res->{ok} && $res->{result}) {
    if ($output_directory) {
        my $ts = time();
        my $output = catfile($output_directory, "telegram-getUpdates-$ts.json");
        write_file($output, $JSON->encode($res));
    }
    else {
        say $JSON->encode($res);
    }
}
