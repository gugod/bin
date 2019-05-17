package HTML::Feature::Engine::HTMLExtractContent;
use v5.18;
use warnings;
use HTML::Feature::Result;
use base qw(HTML::Feature::Base);

use HTML::ExtractContent;

sub run {
    my $self     = shift;
    my $html_ref = shift;
    my $url      = shift;
    my $result   = shift;

    unless ($result->text) {
        my $text = HTML::ExtractContent->new->extract($$html_ref)->as_text;
        if ($text) {
            $result->text($text);
            $result->{matched_engine} = "HTMLExtractContent";
        }
    }

    return $result;
}

1;
