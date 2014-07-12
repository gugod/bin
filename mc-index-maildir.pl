#!/usr/bin/env perl
use v5.14; use strict; use warnings;

use Getopt::Std;

use YAML;
use Digest::SHA1 qw(sha1_hex);
use Email::MIME;

use Mail::Box::Manager;

use Encode qw(encode_utf8);

use Sereal::Encoder;

use FindBin;
use lib $FindBin::Bin . "/lib";
use Tokenize;

sub index_document {
    my ($idx, $id_doc, $doc) = @_;

    $idx->{count_document}++;
    # $idx->{documents}{$id_doc} = $doc;

    for my $field (keys %$doc) {
        my $fidx = $idx->{field}{$field} ||= {};
        my @tokens = Tokenize::standard_shingle2_shingle3( $doc->{$field} );

        $fidx->{count_token} += @tokens;

        # say $doc->{$field};
        # say "==" . join ",", @tokens;
        # $fidx->{count_characters} = length($doc->{$field});
        # next;

        my %seen;
        for my $token (@tokens) {
            $fidx->{token}{$token}{count_document}++;
            $seen{$token}++;
            # $fidx->{token}{$token}{count_document}{$id_doc}++;
        }

        $fidx->{count_utoken} += keys %seen;
        for my $token (keys %seen) {
            $fidx->{token}{$token}{ucount_document}++;
        }
    }
}

sub index_maildir {
    my $mgr = shift;
    my $box = shift;
    my $box_idx  = {};

    my $folder = $mgr->open("=${box}", access => "r");
    my $count_message = $folder->messages;
    for my $i (0..$count_message-1) {
        my $message = $folder->message($i);
        my $doc = {
            subject       => "". ($message->head->study("subject") // ""),
            # from          => "". ($message->head->study("from") // ""),
            # 'reply-to'    => "". ($message->head->study("reply-to") // ""),
            # 'message-id'  => "". ($message->head->study("message-id") // ""),
            # 'return-path' => "". ($message->head->study("return-path") // ""),
        };

        my @from = $message->from;

        for my $from_address (map { $_->address} @from) {
            my $doc2 = {%$doc};
            $doc2->{from} = $from_address;

            index_document(
                $box_idx,
                sha1_hex($message),
                $doc2
            );
        }
    }

    return $box_idx;
}

my %opts;
getopts('d:', \%opts);
binmode STDOUT, ":utf8";

my $index_directory = $opts{d} or die "-d /dir/of/index";
mkdir( $index_directory ) unless -d $index_directory;

my $sereal = Sereal::Encoder->new;

my $mgr = Mail::Box::Manager->new( folderdir => "$ENV{HOME}/Maildir/" );

for my $folder_name (@ARGV) {
    my $idx = index_maildir($mgr, $folder_name);

    $folder_name =~ s{\A(.*/)?([^/]+)\z}{$2};
    open my $fh, ">", File::Spec->catdir($index_directory, "${folder_name}.sereal");
    print $fh $sereal->encode($idx);
    close($fh);

    open $fh, ">", File::Spec->catdir($index_directory, "${folder_name}.yml");
    print $fh encode_utf8(YAML::Dump($idx));
    close($fh);
}
