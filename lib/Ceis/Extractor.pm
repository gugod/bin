use v5.14;

package Ceis::Extractor {
    use utf8;
    use Moose;
    use Mojo::DOM;
    use List::MoreUtils qw(natatime);
    use WWW::Mechanize::Cached;
    use CHI;

    has url => (
        is => "rw",
        isa => "Str"
    );

    has wanted => (
        is => "rw",
        isa => "Str",
        lazy => 1,
        builder => '_build_wanted',
        clearer => 'clear_wanted',
        predicate => 'has_wanted'
    );

    has exclude => (
        is => "rw",
        isa => "Regexp"
    );

    has ua => (
        is => "ro",
        isa => "WWW::Mechanize",
        builder => '_build_ua',
        lazy => 1
    );

    has response => (
        is        => "rw",
        lazy      => 1,
        builder   => '_build_response',
        clearer   => "clear_response",
        predicate => 'has_response'
    );

    after 'url' => sub {
        my $self = shift;
        $self->clear_response
            if $self->has_response;

        $self->clear_wanted
            if $self->has_wanted;
    };

    sub _build_ua {
        state $ua = WWW::Mechanize::Cached->new;

        return $ua;
    }

    sub _build_response {
        my ($self) = @_;
        die unless $self->url;

        my $response = $self->ua->get($self->url);
        $self->url("". $self->ua->uri);

        return $response;
    }

    sub _build_wanted {
        state $queries = {
            qr{digitimes\.com/}                  => 'title, p.P1, p.P2',
            qr{mobile01\.com/}                   => 'title, .single-post-content',
            qr{\.wordpress\.com/}                => 'h2.entry-title, .post p',
            qr{wretch\.cc/blog}                  => 'h3.title, .innertext p',
            qr{pansci\.tw/}                      => 'h2.posttitle, .entry p',
            qr{\.cna\.com\.tw/}                  => '.new_mid_headline_orange, .new_mid_word_large',
            qr{wikipedia\.org}                   => 'p, h1, h2>span.mw-headline, h3>span.mw-headline',
            qr{www\.techbang\.com\.tw/}          => 'header h2 a, .content h2, .content h3, .content p',
            qr{pcworld\.com/}                    => '#articleHead h1, .articleBodyContent p',
            qr{ameblo\.jp/}                      => 'h3.title, .subContents',
            qr{boingboing\.net/}                 => '.post h2, .post p',
            qr{typepad\.com/}                    => '.entry-header, .entry-body p',
            qr{blogspot\.com/}                   => '.post-title, .post-body',
            qr{theverge\.com/}                   => 'h1.headline, .article-body p',
            qr{gizmag\.com/}                     => 'title, .article_body p',
            qr{http://tw\.myblog\.yahoo\.com/}   => 'h2 span, .msgcontent > :not(.wsharing)',
            qr{http://tw\.news\.yahoo\.com/}     => 'h1, .yom-art-content p',
            qr{tw\.nextmedia\.com/[^/]+/article} => "p, .article_paragraph h1, .article_paragraph h2",
        };
        state $url_regexes = [keys %$queries];

        my ($self) = @_;
        die unless $self->url;

        my $query = "h1, h2, h3, p";

        for my $re (@$url_regexes) {
            if ($self->url =~ m/$re/) {
                $query = $queries->{$re};
                last;
            }
        }

        return $query;
    }

    sub fulltext {
        my ($self) = @_;
        my @result;

        my $exclude = $self->exclude;

        my $dom = Mojo::DOM->new( $self->response->decoded_content);

        $dom->find("style, script")->each(sub { $_[0]->replace("<div></div>") });

        my $result = "";

        $dom->find($self->wanted)->each(
            sub {
                local $_ = $_[0]->all_text(0);
                return if /\A\s*\Z/;
                return if $exclude && /$exclude/;
                s/[\r\n]+//g;
                $result .= $_ . "\n\n";
            }
        );

        return $result;
    }

};

1;
