#!/usr/bin/env perl
#
# This program should only be ran once in a day, presumably from a crontab.
# It is the best to run in in at 00:01.
#

use v5.14;
use encoding 'utf8';

package TransmissionFeeder;
use Moose;
use Moose::Util::TypeConstraints;
use XML::Feed;
use Try::Tiny;
use Transmission::Client;
use URI;
use DateTime;

subtype 'TransmissionFeeder::Feed' => as class_type 'XML::Feed';

coerce 'TransmissionFeeder::Feed' => from 'Str' => via  { XML::Feed->parse(URI->new($_)) };

has feed => (
    is => "rw",
    isa => "TransmissionFeeder::Feed",
    required => 1,
    coerce => 1
);

has transmission_client => (
    is => "rw",
    isa => "Transmission::Client",
    builder => '_build_transmission_client',
    lazy => 1
);

has options => (
    is => "rw",
    isa => "HashRef"
);

sub run {
    my $self = shift;
    my $today = DateTime->today;

    my @feeds;

    for my $entry ($self->feed->entries) {
        my $delta = $today - $entry->issued->truncate(to => 'day');

        if ($self->options->{'only-today'}) {
            if ( $delta->days == 0) {
                push @feeds, [$entry->title, $entry->content->body];
            }
        }
        else {
            push @feeds, [$entry->title, $entry->content->body];
        }
    }

    for my $pattern (@{ $self->options->{only} ||[] }) {
        @feeds = grep { $_->[0] =~ /$pattern/ } @feeds;
    }

    for my $pattern (@{ $self->options->{exclude} ||[] }) {
        @feeds = grep { $_->[0] !~ /$pattern/ } @feeds;
    }

    for (@feeds) {
        if ($self->options->{'dont-run'}) {
            say "Add: " . $_->[0];
        }
        else {
            try {
                $self->transmission_client->add(filename => $_->[1]);
            }
        }
    }
}

sub _build_transmission_client {
    my $self = shift;
    my %opts = ( autodie => 1 );

    for (grep { defined($_->[1]) } map { [$_, $self->options->{$_}] } qw(url username password)) {
        $opts{$_->[0]} = $_->[1];
    }

    return Transmission::Client->new(%opts);
}

package main;
use utf8;
use Getopt::Long;
use Pod::Usage;

utf8::decode($_) for @ARGV;

my %options;

GetOptions(
    \%options,
    'dont-run',
    'url=s',
    'username=s',
    'password=s',
    'only=s@',
    'exclude=s@',
    'only-today',
);

my $feed_url = shift @ARGV or pod2usage({ -verbose => 1, -exitval => 1 });

my $feeder = TransmissionFeeder->new(
    options => \%options,
    feed => $feed_url
);

$feeder->run;

__END__

=head1 SYNOPSIS

feed-torrents-to-transmission.pl [options] <URL>

--dont-run

    Do not really add torrents into Transmission. Print their name instead.

--url <url>

    Transmission RPC URL

--username <xxx>

    Transmission RPC Username

--password <yyy>

    Transmission RPC Password

--only <regex>

    A regex (without the surrounding //) to match against feed entry names to
    narrow down the items to feed to transmission.  This option may be given
    multiple times. Feed entry names matching all of the regexes are fed to
    transmission.

--exclude <regex>

    A regex (without the surrounding //) to match against feed entry names to
    exclude.  This option can be given multiple times. Feed entry names matching
    any one of the regexes are excluded.
