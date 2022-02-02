#!/usr/bin/env perl
use v5.26;
use utf8;
use feature 'signatures';

use Twitter::API ();
use YAML ();
use Encode ('decode_utf8');
use Getopt::Long ('GetOptionsFromArray');

sub main {
    my @args = @_;

    my %opts;
    GetOptionsFromArray(
        \@args,
        \%opts,
        'c=s',
        'y|yes'
    ) or die("Error in arguments, but I'm not telling you what it is.");

    my $msg = shift @args;

    maybe_tweet_update(\%opts, $msg);

    return 0;
}

exit(main(@ARGV));

sub maybe_tweet_update ($opts, $msg) {
    unless ($msg) {
        say "# Message is empty.";
        return;
    }

    $msg = decode_utf8($msg) unless utf8::is_utf8($msg);

    my $config;

    if ($opts->{c} && -f $opts->{c}) {
        say "[INFO] Loading config from $opts->{c}";
        $config = YAML::LoadFile( $opts->{c} );
    } elsif ($opts->{'github-secret'} && $ENV{'TWITTER_TOKENS'}) {
        say "[INFO] Loading config from env";
        $config = YAML::Load($ENV{'TWITTER_TOKENS'});
    } else {
        say "[INFO] No config.";
    }

    if ($opts->{y} && $config) {
        say "#=> Tweet for real";
        my $twitter = Twitter::API->new_with_traits(
            traits => "Enchilada",
            consumer_key        => $config->{consumer_key},
            consumer_secret     => $config->{consumer_secret},
            access_token        => $config->{access_token},
            access_token_secret => $config->{access_token_secret},
        );

        my $r = $twitter->update($msg);
        say "https://twitter.com/" . $r->{"user"}{"screen_name"} . "/status/" . $r->{"id_str"};
        say YAML::Dump($r);
    } else {
        say "#=> Not tweeting";
    }
}
