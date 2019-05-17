#!/usr/bin/env perl
use v5.18;
use warnings;

use JSON::PP;
use WWW::Telegram::BotAPI;
use Getopt::Long qw(GetOptions);
use File::Slurp qw(write_file);
use File::Spec::Functions qw(catfile);
use List::MoreUtils qw(minmax);

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

my $offset;
if ($output_directory) {
    my @previous_output = glob( catfile($output_directory, "telegram-getUpdates-*-*.json") );
    if (@previous_output) {
        (undef, $offset) = minmax(map { (split /[-\.]/)[4] } @previous_output );
        $offset += 1;
        print $offset;
    }
}

my $JSON = JSON::PP->new->utf8->canonical;
my $bot = WWW::Telegram::BotAPI->new( token => $opts{token} );
my $res = $bot->api_request('getMe');

$res = $bot->api_request(
    'getUpdates',
    { timeout => 12, ($offset ? (offset => $offset): ()) },
);

if ($res && $res->{ok} && $res->{result}) {
    if ($output_directory) {
        if ($res->{ok} &&  @{$res->{result}}) {
            my ($min,$max) = minmax(map { $_->{update_id} } @{$res->{result}} );
            my $output = catfile($output_directory, "telegram-getUpdates-$min-$max.json");
            write_file($output, $JSON->encode($res));
        } else {
            warn "FAIL";
        }
    }
    else {
        say $JSON->encode($res);
    }
}
