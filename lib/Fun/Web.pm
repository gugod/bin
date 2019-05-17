package Fun::Web;
use v5.18;
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
    my ($url, $res);

    if (! ref($_[0])) {
        $url = $_[0];
        my $ua = Mojo::UserAgent->new->max_redirects(10);
        my $tx = $ua->get($url);
        $res = $tx->res;
    } else {
        $res = $_[0];
    }
    
    my $dom = $res->dom;

    my $charset;
    my $content_type = $res->headers->content_type;

    if ( $content_type && $content_type !~ /html/) {
        return undef;
    }

    if ( $content_type && $content_type =~ m!charset=(.+)[;\s]?!) {
        $charset = $1;
    }
    if (!$charset) {
        if (my $meta_el = $dom->find("head meta[http-equiv=Content-Type]")->first) {
            ($charset) = $meta_el->{content} =~ m{charset=([^\s;]+)};
            $charset = lc($charset) if defined($charset);
        }
    }
    $charset ||= "utf-8";

    my $html = Encode::decode($charset, $res->body);

    my $title = $dom->find("title");
    if ($title->size > 0) {
        $title = $title->[0]->text;
        $title = Encode::decode($charset, $title) unless $title && Encode::is_utf8($title);
    } else {
        $title = "";
    }

    my $extractor = HTML::ExtractContent->new;
    my $text = $extractor->extract($html)->as_text;

    return {
        title => $title,
        text  => "$text",
        html  => "$html",
    }
}

my %sns_hosts = map { $_ => 1 } (
    "twitter.com",
    "facebook.com",
    "www.facebook.com",
    "www.instagram.com",
    "m.facebook.com",
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

my %news_hosts = map { $_ => 1 } (
    "udn.com",
    "newtalk.tw",
    "www3.nhk.or.jp",
);
sub host_is_news {
    my ($host) = @_;
    return 1 if $host =~ /\A www\.huffingtonpost\.(fr|jp) /x;
    return 1 if $host =~ /\A [a-z]+\.cnn.com /x;
    return 1 if $host =~ / news\.yahoo\. /x;
    return 1 if $news_hosts{$host};
    return 0;
}

1;
