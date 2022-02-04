#!/usr/bin/pugs

=head1 NAMES

rename-to-ascii.p6 - Rename a file using limited ascii characters.

=head1 USAGE

  rename-to-ascii.p6 <file-name-with-messy-characters-hard-to-input>

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

use v6;

my $_ = @ARGS[0];

s:perl5/\s*$//;
s:perl5/^\s*//;
s:perl5:g/\s/-/;
s:perl5:g/[^a-zA-Z\-_0-9]//;

if /^\-*$/ {
    $_ = "file-name";
}

unless $_ == @ARGS[0] {
    my $new_file = $_;
    my $i;

    while -f $new_file {
        $new_file = $_ ~ $i;
        $i++
    }

    rename(@ARGS[0], $new_file)
        unless @ARGS;
}

