#!/usr/bin/env perl
use v5.18;

open my $out, ">", "index.html";

say $out <<HTML_BEGIN;
<!doctype html>
<html>
<head>
<meta charset="utf-8">
</head>
<body>
<ul>
HTML_BEGIN

my @files = <*.*>;

for my $file (@files) {
    say $out qq[<li><a href="$file">$file</li>];
}

say $out <<HTML_END;
</ul>
</body>
</html>
HTML_END
