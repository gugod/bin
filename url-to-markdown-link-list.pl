use v5.18;
use strict;

use Mojo::UserAgent;
# use Firefox::Marionette qw(:all);

use FindBin;
use lib $FindBin::Bin . "/lib";
use Fun::Web qw(extract_title_and_text url_remove_tracking_params url_unshorten);

my $mojoua = Mojo::UserAgent->new;
$mojoua->max_redirects(5);

# my $firefox = Firefox::Marionette->new( profile => jabbot, visible => 1 );

sub markdown_link_text_normalize {
    my $txt = $_[0];
    $txt =~ s/\[/\\\[/g;
    $txt =~ s/\]/\\\]/g;
    $txt =~ s/\s+/ /g;
    $txt =~ s/\A\s+//g;
    $txt =~ s/\s+\z//g;
    return $txt;
}

while(<>) {
    chomp;
    my $tx = $mojoua->get($_);
    next unless $tx->res->is_success;

    my $o = extract_title_and_text($tx->res);
    next unless $o->{title};

    my $url = url_remove_tracking_params( $tx->req->url->to_abs );
    my $msg = "- [" . markdown_link_text_normalize($o->{title}) . "]($url)\n";
    utf8::encode($msg);
    print $msg;
}
