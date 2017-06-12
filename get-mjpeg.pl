#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;

use Carp::Always;

use constant CRLF => "\015\012";
my $CRLF = CRLF();

use Time::HiRes ();
use Data::Dumper qw(Dumper);
use LWP::UserAgent;
use File::Slurp qw(write_file);
use File::Path qw(make_path);
use File::Spec;
use Getopt::Long qw(GetOptions);

sub on_mime_part {
    my ($content_type, $content_length, $part, $output_dir) = @_;
    my $t = int(1000*Time::HiRes::time());
    my $ofh = File::Spec->catfile($output_dir, "img-${t}.jpg");
    write_file($ofh, $part);
    say "$ofh <= $content_type $content_length";
}

local $|;

my %opts;
GetOptions(
    \%opts,
    "o|output=s",
);

my $url = shift(@ARGV) or die "Requires an URL";
my ($boundary, $boundary_line);
my $response_content = "";
my $response_part = "";
my $output_dir = $opts{o} // $opts{output};

unless (-d $output_dir) {
    if (-e $output_dir) {
        die "ERROR: The path $output_dir already exists and it is not a directory.";
    }
    make_path($output_dir);
}

my $ua = LWP::UserAgent->new(
    timeout => 60,
);

$ua->add_handler(
    response_header =>  sub {
        my ($response, $ua, $h) = @_;
        die "Non-successful response." unless $response->is_success;
        my $ct = $response->header("Content-Type");
        ($boundary) = $ct =~ m{multipart/x-mixed-replace; boundary=(.+)$};
        die "No boundary separator" unless $boundary;
        $boundary_line = $boundary;
        # $boundary_line = "${boundary}${CRLF}";
        # $boundary_line =~ s/^----/--/;
        return 1;
    }
);
$ua->add_handler(
    response_data => sub {
        my ($response, $ua, $h, $chunk) = @_;

        $response_content .= $chunk;

        if ($response_content =~ /\A\s+${boundary_line}/x) {
            my $head_pos = index($response_content, "${CRLF}${CRLF}");
            my $head = substr($response_content, length($boundary_line), $head_pos - length($boundary_line));
            my @headers = map { split(/:\s*/, $_, 2) } split(/${CRLF}/, $head);

            if (@headers % 2 == 1 && $headers[0] =~ /\A--/) {
                shift @headers;
            }

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
                on_mime_part($content_type, $content_length, $part, $output_dir);
                substr($response_content, 0, $head_pos + 4 + $content_length) = "";
                while (index($response_content, $CRLF) == 0) {
                    substr($response_content, 0, length($CRLF)) = "";
                }
            }
        } else {
            die "Missing mime boundary <$boundary>\n" . "--\n" . (substr($response_content, 0, 140) =~ s/\P{ascii}/./r) . "--\n";
        }

        return 1;
    }
);
my $res = $ua->get($url);
my $died = $res->headers("X-Died");
if ($died) {
    say "ERR: $died";
}
