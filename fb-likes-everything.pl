#!/usr/bin/env perl

use v5.28;
use utf8;

use Log::Log4perl qw(:easy);

use WWW::Mechanize::Chrome;

binmode STDOUT, ":utf8";

Log::Log4perl->easy_init($ERROR);

my $mech = WWW::Mechanize::Chrome->new();
$mech->get('https://mbasic.facebook.com');
sleep 8;

my (@like_buttons, $like_button, %clicked);
while(1) {
    @like_buttons = grep {
        my $href = $_->get_attribute('href');
        ! $clicked{$href};
    } $mech->find_all_links_dom( url_regex => qr{/a/like\.php} );

    unless (@like_buttons) {
        $mech->get('https://mbasic.facebook.com');
        sleep 8;
        redo;
    }

    do {
        $like_button = $like_buttons[ rand() * @like_buttons ]
    } while !$like_button;

    my $href = $like_button->get_attribute('href');
    say "<<< " . $like_button->get_text() . " >>> $href";
    $mech->click({ dom => $like_button });
    $clicked{$href} = 1;
    sleep 5 + rand(10);
}
