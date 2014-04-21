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

binmode STDOUT, ":utf8";

sub test_maildir {
    my $count_pass = 0;
    my $count_unsure = 0;
    my $count_sure = 0;

    my $idx = shift;
    my $box = shift;
    my $folder = Email::Folder::Maildir->new($box);
    while (my $message = $folder->next_message ) {
        my $email = Email::MIME->new($message);
        my $doc = {
            subject => decode_utf8( $email->header("Subject"), Encode::FB_QUIET ),
            from    => decode_utf8( $email->header("From"), Encode::FB_QUIET ),
        };

        my %guess;

        for my $field (keys %$doc) {
            my @tokens = Tokenize::by_script_with_ngram_and_shingle($doc->{$field}) or next;

            my (%matched, %score);
            for my $category (keys %$idx) {
                for (@tokens) {
                    $matched{$_} = $idx->{$category}{field}{$field}{token}{$_}{count_document} || 0;
                }
                my $count_matched = sum(map { $_ ? 1 : 0 } values %matched) || 0;
                $score{$category} = $count_matched / @tokens;
            }

            my @c = sort { $score{$b} <=> $score{$a} } keys %score;

            $guess{$field} = {
                fieldLength => 0+@tokens,
                category   => $c[0],
                confidence => $score{$c[0]} / (sum(values %score) ||1),
                categories => \@c,
                score => \%score,
            };
        }

        my @guess = keys %guess;
        if (@guess > 0) {
            if (1 == uniq(map { $guess{$_}->{category} } @guess)) {
                $count_sure++;
                my $g = $guess{ $guess[0] };
                my $category = $g->{category};
                my $confidence = $g->{confidence};

                if ($category eq 'Junk') {
                    $count_pass++;
                }
                say "$category(l=@{[ $g->{fieldLength} ]},s=@{[ $g->{score}{$category} ]},c=$confidence)\t$doc->{subject}";
            } else {
                $count_unsure++;
                say "(???)\t$doc->{subject}";
                say "\t" . $json->encode(\%guess);
                # say "\t".join "," => map { $_ . ":" . sprintf('%.2f', $score{$_} ) } @c;
            }
        } else {
            say "(!!!)\t$doc->{subject}";
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
for(<$index_directory/*.sereal>) {
    open my $fh, "<", $_;
    my $box_name = basename($_) =~ s/\.sereal$//r;
    local $/ = undef;
    $idx->{$box_name} = $sereal->decode(<$fh>);
}

for my $box (@ARGV) {
    my $box_name = basename($box);
    my $idx = test_maildir($idx, $box);
}
