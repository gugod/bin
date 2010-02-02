#!/usr/bin/env perl
use common::sense;
use Net::Twitter;
use YAML;
use Try::Tiny;

my ($user, $password) = @ARGV;
die "Need user and password\n" unless $user && $password;

my $t = Net::Twitter->new(
    traits   => [qw/API::REST/],
    username => $user,
    password => $password
);

while (my $statuses = $t->user_timeline) {
    for (@$statuses) {
        my $id = $_->{id};
        try {
            $t->destroy_status($id);
            say "Removed: $id /  $_->{text}";
        } catch {
            say "Error deleting $id";
        }
    }
}
