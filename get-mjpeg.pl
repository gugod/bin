#!/usr/bin/env perl
use v5.18;
use strict;

use constant CRLF => "\015\012";
my $CRLF = CRLF();

use Time::HiRes ();
use Data::Dumper qw(Dumper);
use LWP::UserAgent;
use File::Slurp qw(write_file);

sub on_mime_part {
    my ($content_type, $content_length, $part) = @_;
    my $t = int(1000*Time::HiRes::time());
    my $ofh ="/tmp/img-${t}.jpg";
    write_file($ofh, $part);
    say "$ofh <= $content_type $content_length";
}

local $|;

my $url = shift(@ARGV) or die;
my ($boundary, $boundry_line);
my $response_content = "";
my $response_part = "";

my $ua = LWP::UserAgent->new;
$ua->add_handler(
    response_header =>  sub {
        my ($response, $ua, $h) = @_;
        die "Non-successful response." unless $response->is_success;
        my $ct = $response->header("Content-Type");
        ($boundary) = $ct =~ m{multipart/x-mixed-replace; boundary=(.+)$};
        die "No boundary separator" unless $boundary;

        $boundary_line = "--${boundary}${CRLF}";
        $boundary_line =~ s/^----/--/;
    }
);
$ua->get(
    $url,
    ':read_size_init' => 10240,
    ':content_cb' => sub {
        my ($chunk, $response, $proto) = @_;

        $response_content .= $chunk;
        my $pos = index($response_content, $boundary_line);
        if ($pos == 0) {
            my $head_pos = index($response_content, "${CRLF}${CRLF}");
            my $head = substr($response_content, length($boundary_line), $head_pos - length($boundary_line));

            my @headers = map { split(/:/, $_, 2) } split(/${CRLF}/, $head);

            my ($content_type, $content_length);
            for (my $i = 0; $i < @headers; $i += 2) {
                my $field = lc($headers[$i]);
                my $value = $headers[$i+1];
                if ( (!defined($content_type)) && ($field eq 'content-type') ) {
                    $content_type = $value;
                }
                if ( (!defined($content_length)) && ($field eq 'content-length') ) {
                    $content_length = $value;
                }
            }

            if (length($response_content) >= length($boundary_line) + length($head) + 4 + $content_length) {
                my $part = substr($response_content, $head_pos + 4, $content_length);
                on_mime_part($content_type, $content_length, $part);
                substr($response_content, 0, $head_pos + 4 + $content_length) = "";
                while (index($response_content, $CRLF) == 0) {
                    substr($response_content, 0, length($CRLF)) = "";
                }
            }
        } else {
            say "Ok, what's going on...: boundary=<$boundary>";
            say "<" . substr($response_content, 0, length($boundary)*2) . ">";
        }
        return 1;
});
