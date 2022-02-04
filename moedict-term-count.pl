#!/usr/bin/env perl
use v5.32;
use utf8;
use Encode qw( encode_utf8 );
use JSON qw( decode_json );
use feature qw( signatures );
use Path::Tiny qw( path );
use Getopt::Long qw( GetOptions );

## main
my %opts;
GetOptions(
    \%opts,
    "moedict=s",
);

defined($opts{"moedict"}) or die "--moedict=moedict-data/dict-revised.json\n";

say @ARGV;
my $dict = load_moedict($opts{"moedict"});

my $freq = {};
for my $input (@ARGV) {
   count_this($input, $dict, $freq);
}
print_freq($freq);

exit(0);

##

sub load_moedict ( $moedict_filename ) {
    my $dict = {};
    my $records = decode_json( scalar path($moedict_filename)->slurp );
    for my $rec (@$records) {
        if ( ($rec->{"title"} //"") =~ /\p{Script=Han}/ ) {
            $dict->{ $rec->{"title"} } = 1;
        }
    }
    return $dict;
}

sub count_this ($input, $dict, $freq) {
    my $content = path($input)->slurp_utf8;

    $content =~ s/\n//g;

    my @snippets = $content =~ m/(\p{Script=Han}+)/g;
    for my $snippet (@snippets) {
        # say encode_utf8(">>> $snippet");
        my @chars = split("", $snippet);
        for my $char (@chars) {
            $freq->{$char}++;
        }
        for my $len (2,3,4) {
            for my $i (0...(@chars-$len)) {
                my $tok = join("", @chars[$i ... ($i+$len-1)]);
                # say encode_utf8(">>>>>> $tok");
                if ($dict->{$tok}) {
                    $freq->{$tok}++;
                }
            }
        }
    }
}

sub print_freq ($freq) {
    my @ks = sort { $freq->{$b} <=> $freq->{$a} } keys %$freq;
    while (@ks) {
        my $k = shift @ks;
        say encode_utf8( $k . "\t" . $freq->{$k} );
    }
}
