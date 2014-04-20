#!/usr/bin/env perl
use v5.14; use strict; use warnings;

use YAML;
use Digest::SHA1 qw(sha1_hex);
use Email::MIME;
use Email::Delete qw(delete_message);

use Email::Folder::Maildir;

use Encode qw(decode_utf8);
use File::Basename 'basename';

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
        $fidx->{count_token} += my @tokens = Tokenize::by_script_than_ngram($doc->{$field});

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
    my $box = shift;
    my $box_idx  = {};
    my $folder = Email::Folder::Maildir->new($box);
    while (my $message = $folder->next_message ) {
        my $email = Email::MIME->new($message);
        index_document(
            $box_idx,
            sha1_hex($message),
            {
                subject => decode_utf8( $email->header("Subject"), Encode::FB_QUIET ),
                body    => decode_utf8( $email->body, Encode::FB_QUIET ),
            }
        );
    }
    return $box_idx;
}

my $sereal = Sereal::Encoder->new;
mkdir("/tmp/maildir_idx/");
binmode STDOUT, ":utf8";
for my $box (@ARGV) {
    my $box_name = basename($box);
    my $idx = index_maildir($box);

    open my $fh, ">", "/tmp/maildir_idx/${box_name}.sereal";
    print $fh $sereal->encode($idx);
    close($fh);
}
