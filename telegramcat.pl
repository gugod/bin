#!/usr/bin/env perl
use v5.18;
use warnings;
use WWW::Telegram::BotAPI;
use Getopt::Long qw(GetOptions);

my %opts;
GetOptions(
    \%opts,
    "chat-id=s",
    "token=s",
);
$opts{chat_id} = $opts{'chat-id'};
die "Require both `token` and `chat-id`" unless $opts{token} && $opts{chat_id};

my $bot = WWW::Telegram::BotAPI->new( token => $opts{token} );
my $tx = $bot->api_request('getMe');

while(<>) {
    chomp;
    my $content = $_;

    $bot->api_request(
        sendMessage => {
            chat_id => $opts{chat_id},
            text    => $content
        }
    );

    sleep 1;
}
