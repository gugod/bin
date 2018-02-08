package Fun::Web;
use v5.18;
use strict;
use warnings;

use parent 'Exporter';
use Module::Functions;
our @EXPORT_OK = get_public_functions();

use Mojo::UserAgent;
use Encode;
use HTML::ExtractContent;
use URI;
use URI::QueryParam;

sub url_remove_tracking_params {
    my ($url) = @_;
    my $o = URI->new($url);
    for my $k ($o->query_param) {
        if ($k =~ /\A utm_[a-z0-9]+ \z/x) {
            $o->query_param_delete($k);
        }
    }
    return "$o";
}

sub url_unshorten {
    my $url = shift;
    my $ua = Mojo::UserAgent->new->max_redirects(10)->max_response_size(4096);
    my $tx = $ua->get($url);
    return $tx->req->url->to_abs . "";
}

sub extract_title_and_text {
    my $url = shift;
    my $ua = Mojo::UserAgent->new->max_redirects(10);
    my $tx = $ua->get($url);

    my $base_url = URI->new($url);
    my $dom = $tx->res->dom;
    my $content_type = $tx->res->headers->content_type;

    my $charset;
    if ($content_type =~ m!charset=(.+)[;\s]?!) {
        $charset = $1;
    }
    if (!$charset) {
        if (my $meta_el = $dom->find("head meta[http-equiv=Content-Type]")->first) {
            ($charset) = $meta_el->{content} =~ m{charset=([^\s;]+)};                    
        }
    }
    $charset ||= "utf-8";

    my $html = Encode::decode($charset, $tx->res->body);

    my $title = $dom->find("title");
    if ($title->size > 0) {
        $title = $title->[0]->text;
        $title = Encode::decode($charset, $title) unless $title && Encode::is_utf8($title);
    } else {
        $title = "";
    }

    my $extractor = HTML::ExtractContent->new;
    my $text = $extractor->extract($html)->as_text
        =~ s!^ \S{1,4} $!!xmgr
        =~ s!\n!\n\n!gr
        =~ s!\n\n+!\n\n!gr;

    return {
        title => $title,
        text  => "$text",
    }
}

my %sns_hosts = map { $_ => 1 } (
    "twitter.com",
    "facebook.com",
    "www.facebook.com",
    "www.instagram.com",
);
sub host_is_sns {
    return $sns_hosts{$_[0]};
}

my %video_hosts = map { $_ => 1 } (
    "www.youtube.com",
    "www.twitch.tv",
);
sub host_is_video {
    return $video_hosts{$_[0]}
}

1;
