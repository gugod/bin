package Fun::Text;
use v5.18;
use warnings;

use Exporter 'import';
use Module::Functions;
our @EXPORT_OK = get_public_functions();

sub markdown_link_text_normalize {
    my $txt = $_[0];
    $txt =~ s/\[/\\\[/g;
    $txt =~ s/\]/\\\]/g;
    $txt =~ s/\s+/ /g;
    $txt =~ s/\A\s+//g;
    $txt =~ s/\s+\z//g;
    return $txt;
}

1;
