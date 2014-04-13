#!/usr/bin/env perl
use v5.14; use strict; use warnings;

use YAML;
use Digest::SHA1 qw(sha1_hex);
use Email::MIME;
use Email::Delete qw(delete_message);

use Email::Folder::Maildir;

use Encode qw(decode_utf8);
use File::Basename 'basename';

use FindBin;
use lib $FindBin::Bin . "/lib";
use Tokenize;

sub ngram($) {
    my @t;
    my $s = $_[0];
    my $l = length($s);
    while($l > 1) {
        for (1..$l) {
            push @t, substr($s, 0, $_);
        }
        $s = substr($s, 1);
        $l = length($s);
    }
    return @t;
}

sub tokenize($) {
    return map {
        s/\A\s+//;
        s/\s+\z//;
        $_ eq '' ? () : ( ngram( lc($_) ) )
    } Tokenize::by_script($_[0]);
}

sub index_document {
    my ($idx, $id_doc, $doc) = @_;

    $idx->{count_document}++;
    # $idx->{documents}{$id_doc} = $doc;

    for my $field (keys %$doc) {
        my $fidx = $idx->{field}{$field} ||= {};
        $fidx->{count_token} += my @tokens = tokenize($doc->{$field});

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

binmode STDOUT, ":utf8";

my %idx;
for my $box (@ARGV) {
    my $box_name = basename($box);
    my $box_idx  = $idx{$box_name} = {};
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
}

say YAML::Dump(\%idx);

# my @top = sort { $token{$b} <=> $token{$a} } keys %token;
# for (splice(@top,0,25)) {
#     say "$token{$_}/$count_doc\t<$_>";
# }
