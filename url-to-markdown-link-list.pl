use v5.18;

use HTML::Strip;
use Mojo::UserAgent;
# use Firefox::Marionette qw(:all);

use FindBin;
use lib $FindBin::Bin . "/lib";
use Fun::Web qw(extract_title_and_text url_remove_tracking_params);

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

my %seen;

while(<>) {
    chomp;
    next if $seen{$_};
    $seen{$_} = 1;

    my $tx = $mojoua->get($_);
    next unless $tx->res->is_success;

    my $o = extract_title_and_text($tx->res);
    next unless $o->{title};

    my $url = url_remove_tracking_params( $tx->req->url->to_abs );
    next if $seen{$url};
    $seen{$url} = 1;

    my $msg = "- [" . markdown_link_text_normalize($o->{title}) . "]($url)";
    if ($o->{text}) {
        my $txt = HTML::Strip->new->parse($o->{text});
        $txt =~ s/[\t\n ]+/ /g;
        $txt =~ s/[\t\n ]+\z//g;
        $txt =~ s/\A[\t\n ]+//g;
        $msg .= " . $txt";
    }
    utf8::encode($msg);
    say $msg;
}
