#!/usr/bin/env perl
#
# This program should only be ran once in a day, presumably from a crontab.
# It is the best to run in in at 00:01.
#

use v5.14;
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

has transmission_client_attributes => (
    is => "rw",
    isa => "HashRef",
    default => sub { {} }
);


sub run {
    my $self = shift;
    my $today = DateTime->today;

    my @todays;

    for my $entry ($self->feed->entries) {
        my $delta = $today - $entry->issued->truncate(to => 'day');

        if ( $delta->days == 0) {
            push @todays, [$entry->title, $entry->content->body];
        }
    }

    for (@todays) {
        try {
            $self->transmission_client->add(filename => $_->[1]);
        }
    }
}

sub _build_transmission_client {
    my $self = shift;
    my %attr = %{$self->transmission_client_attributes};

    return Transmission::Client->new(%attr, autodie => 1);
}

package main;
use Getopt::Long;
use Pod::Usage;

my ($url, $username, $password);
GetOptions(
    "url=s"      => \$url,
    "username=s" => \$username,
    "password=s" => \$password,
);

my $feed_url = shift @ARGV or pod2usage({ -verbose => 1, -exitval => 1 });

my $feeder = TransmissionFeeder->new(
    transmission_client_attributes => {
        @{$url      ? [ url      => $url      ] : []},
        @{$username ? [ username => $username ] : []},
        @{$password ? [ password => $password ] : []},
    },
    feed => $feed_url
);

$feeder->run;

__END__

=head1 SYNOPSIS

feed-torrents-to-transmission.pl [options] <URL>

--url <url>      Transmission RPC URL
--username <xxx> Transmission RPC Username
--password <yyy> Transmission RPC Password
