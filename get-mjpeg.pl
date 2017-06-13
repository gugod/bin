#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;

use Carp::Always;

use constant CRLF => "\015\012";
my $CRLF = CRLF;

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

sub extract_one_part_maybe {
    my ($response_content, $boundary, $output_dir) = @_;
    my $error;

    $response_content =~ s/\A(${CRLF})+//;
    if ($response_content =~ /\A$boundary/x) {
        my $length_delimiter = length("${CRLF}${CRLF}");
        my $head_pos = index($response_content, "${CRLF}${CRLF}");
        if ($head_pos > 0) {
            my $head = substr($response_content, length($boundary), $head_pos - length($boundary));
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

            if (defined($content_type)) {
                if (defined($content_length)) {
                    if (length($response_content) >= length($boundary) + length($head) + $length_delimiter + $content_length) {
                        my $part = substr($response_content, $head_pos + $length_delimiter, $content_length);
                        on_mime_part($content_type, $content_length, $part, $output_dir);
                        substr($response_content, 0, $head_pos + $length_delimiter + $content_length) = "";
                    }
                } else {
                    my $headless_response_content = substr($response_content, $head_pos + $length_delimiter);
                    my @parts = split(/\Q$boundary\E/, $headless_response_content, 2);
                    if (@parts == 2) {
                        my $part = $parts[0];
                        $response_content = $boundary . $parts[1];
                        $part =~ s/(${CRLF})+\z//;
                        on_mime_part($content_type, length($part), $part, $output_dir);
                    }
                }
            }
        }
    } else {
        $error = "Missing mime boundary <$boundary>\n" . (substr($response_content, 0, 140) =~ s/\P{ascii}/./r) . "--\n";
    }

    return ($response_content, $error);
}

sub MAIN {
    my ($self) = @_;

    my $url = $self->{args}[0] or die "Requires an URL";

    my $boundary;
    my $response_content = "";
    my $response_part = "";
    my $output_dir = $self->{opts}{o} // $self->{opts}{output};

    unless (-d $output_dir) {
        if (-e $output_dir) {
            die "ERROR: The path $output_dir already exists and it is not a directory.";
        }
        make_path($output_dir);
    }

    my $ua = LWP::UserAgent->new(
        timeout => 60,
        agent => 'Mozilla/5.0 (X11; Linux x86_64; rv:45.0) Gecko/20100101 Firefox/45.0',
    );

    $ua->add_handler(
        response_header =>  sub {
            my ($response, $ua, $h) = @_;
            die "Non-successful response." unless $response->is_success;
            my $ct = $response->header("Content-Type");
            ($boundary) = $ct =~ m{\A multipart/x-mixed-replace; \s* boundary=(.+) \z}x;
            die "No boundary separator" unless $boundary;
            if ($boundary !~ /\A--/) {
                $boundary = "--$boundary";
            }
            return 1;
        }
    );
    $ua->add_handler(
        response_data => sub {
            my ($response, $ua, $h, $chunk) = @_;

            $response_content .= $chunk;

            # say "Length: " . length($response_content);
            ($response_content, my $error) = extract_one_part_maybe($response_content, $boundary, $output_dir);
            if ($error) {
                die $error;
            }
            return 1;
        }
    );
    my $res = $ua->get($url);
    my $died = $res->header("X-Died");
    if ($died) {
        say "ERR: $died";
    }
}

my %opts;
GetOptions(
    \%opts,
    "o|output=s",
);

(bless {
    opts => \%opts,
    args => \@ARGV,
} => __PACKAGE__)->MAIN();
