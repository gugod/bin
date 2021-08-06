#!/usr/bin/env raku

use YAMLish;
use Twitter;

subset Path of Str where .defined && .IO.f;

sub MAIN (
    Str $tweet,   #= The message to tweet.
    Path :$config #= Path to an existing twitter.yml config file.
) {
    my $twitter;

    my %config = load-yaml(slurp($config));
    $twitter = Twitter.new:
               consumer-key => %config<consumer_key>,
               consumer-secret => %config<consumer_secret>,
               access-token => %config<access_token>,
               access-token-secret => %config<access_token_secret>;

    my %res = $twitter.tweet: $tweet;

    if (%res<id_str>) {
        say "https://twitter.com/{ %res<user><screen_name> }/status/{ %res<id_str> }";
    } else {
        say "Failed: { %res.gist }";
        return 1;
    }

    return 0;
}
