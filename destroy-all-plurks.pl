#!/usr/bin/env perl
use common::sense;
use YAML;
use Try::Tiny;
use LWP::UserAgent;
use JSON;

my ($apikey, $user, $password) = @ARGV;
die "Need apikey, user and password\n" unless $apikey && $user && $password;

my $ua = LWP::UserAgent->new;

$ua->cookie_jar({file => "/tmp/plurk_cookies.txt"});

my $response =  $ua->post("https://www.plurk.com/API/Users/login", {
    api_key  => $apikey,
    username => $user,
    password => $password
});

unless ($response->is_success) {
    say "Fail login";
    exit;
}

my $user_profile = from_json($response->decoded_content);
my $user_id      = $user_profile->{user_info}{id};

say "My user_id is $user_id";

while(1) {
    $response =
        $ua->post("http://www.plurk.com/API/Timeline/getPlurks", {
            api_key      => $apikey,
            minimal_data => 1,
            limit        => 200
        });

    if ($response->is_success) {
        my $plurk_response = from_json($response->decoded_content);
        my @plurks         = grep { $_->{owner_id} == $user_id } @{$plurk_response->{plurks}};

        last unless @plurks;

        for my $plurk (@plurks) {
            if ($plurk->{owner_id} == $user_id) {
                my $response = $ua->post("http://www.plurk.com/API/Timeline/plurkDelete", {
                    api_key      => $apikey,
                    plurk_id     => $plurk->{plurk_id}
                });
                if ($response->is_success) {
                    say "Delete: $plurk->{plurk_id}: $plurk->{owner_id}: $plurk->{content}";
                }
                else {
                    say "Failed to Delete: $plurk->{plurk_id}: $plurk->{owner_id}: $plurk->{content}";
                }
            }
        }
    }
    else {
        say $response->status_line;
    }
}
