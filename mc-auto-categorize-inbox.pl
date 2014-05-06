#!/usr/bin/env perl
use v5.18;
use Data::Dumper;

use Mail::Box::Manager;
use Sereal::Decoder;
use Getopt::Std;
use File::Basename 'basename';

use FindBin;
use lib $FindBin::Bin . "/lib";
use MessageOrganizer;

my %opts;
getopts('d:', \%opts);

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


my $mo  = MessageOrganizer->new( idx => $idx );
my $mgr = Mail::Box::Manager->new( folderdir => "$ENV{HOME}/Maildir/" );

my $folder_inbox = $mgr->open("=INBOX", access => "rw");
my %folder;

for my $folder_name (keys %$idx) {
    $folder{$folder_name} = $mgr->open("=${folder_name}",  access => "a");
}

my $count_message = $folder_inbox->messages;
for my $i (0..$count_message-1) {
    my $message = $folder_inbox->message($i);

    my $message_str = eval { $message->string(); };
    next if $@;

    if (my $category = $mo->looks_like( $message_str )) {
        $mgr->moveMessage($folder{$category}, $message);
    }
}
