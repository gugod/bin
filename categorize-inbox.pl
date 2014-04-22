#!/usr/bin/env perl
use v5.14; use strict; use warnings;

use YAML;
use JSON; my $json = JSON->new->canonical();
use Getopt::Std;

use Digest::SHA1 qw(sha1_hex);
use Encode;
use File::Basename 'basename';
use Sereal::Decoder;
use Email::Folder::Maildir;
use Email::MIME;
use List::Util qw(max sum);
use List::MoreUtils qw(uniq);

use FindBin;
use lib $FindBin::Bin . "/lib";

use Tokenize;
use MessageOrganizer;

binmode STDOUT, ":utf8";

sub test_maildir {
    my $idx = shift;
    my $box = shift;

    my $count_pass = 0;
    my $count_unsure = 0;
    my $count_sure = 0;

    my $mo = MessageOrganizer->new( idx => $idx );

    my $folder = Email::Folder::Maildir->new($box);
    while (my $message = $folder->next_message ) {
        my $category = $mo->looks_like($message);
        if (defined($category)) {

            say "==> $category";

            if ($category eq 'Junk') {
                $count_pass++;
            } else {
                $count_sure++;
            }
        } else {
            $count_unsure++;
        }
    }

    say "count_pass: $count_pass";
    say "count_sure: $count_sure";
    say "count_unsure: $count_unsure";
    say "rate unsure: " . ($count_unsure / ($count_sure + $count_unsure));
}

my %opts;
getopts(
    'd:',
    \%opts
);

my $index_directory = $opts{d} or die "-d /dir/of/index";

my $idx = {};
my $sereal = Sereal::Decoder->new;
for my $fn (<$index_directory/*.sereal>) {
    my $box_name = basename($fn) =~ s/\.sereal$//r;
    next if lc($box_name) eq 'inbox';

    open my $fh, "<", $fn;
    local $/ = undef;
    $idx->{$box_name} = $sereal->decode(<$fh>);
}

for my $box (@ARGV) {
    my $box_name = basename($box);
    my $idx = test_maildir($idx, $box);
}
