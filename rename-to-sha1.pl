#!/usr/bin/env perl

use strict;
use warnings;
use Digest::SHA qw(sha1_hex);
use IO::All;
use File::Find;
use Cwd;

$\="\n";
$|=1;

find( \&rename_it, getcwd);

sub rename_it {
    my $name = $File::Find::name;
    return if -d $name;
    return if $name =~ /\.DS_Store/i;

    my $data = io($name)->all;
    $name = io($name)->canonpath;

    my ($ext) = ($name =~ /\.(.+)$/);
    $ext = lc($ext);

    my $newname = io->catfile(
        io($name)->filepath || "./" ,
        sha1_hex($data) . ".${ext}"
    )->canonpath;

    unless ($name eq $newname) {
        system("mv", $name, $newname);
        print "$name => $newname";
    }
}
