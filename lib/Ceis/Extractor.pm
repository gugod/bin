use v5.14;

package Ceis::Extractor {
    use utf8;
    use Moose;
    use Mojo::DOM;
    use List::MoreUtils qw(natatime);
    use WWW::Mechanize;

    has url => (
        is => "rw",
        isa => "Str"
    );

    has wanted => (
        is => "rw",
        isa => "Str",
        lazy => 1,
        builder => '_build_wanted',
        clearer => 'clear_wanted'
    );

    has exclude => (
        is => "rw",
        isa => "Regexp"
    );

    has response => (
        is        => "rw",
        lazy      => 1,
        builder   => '_build_response',
        clearer   => "clear_response"
    );

    after 'url' => sub {
        my $self = shift;
        $self->clear_response;
        $self->clear_wanted;
    };

    sub _build_response {
        state $ua = WWW::Mechanize->new;

        my ($self) = @_;
        die unless $self->url;
        return $ua->get($self->url);
    }

    sub _build_wanted {
        state $queries = {
            qw{\.cna\.com\.tw/}                  => '.new_mid_headline_orange, .new_mid_word_large',
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

    sub __split_to_sentences {
        my ($text) = @_;

        my @result;
        my $iter = natatime 2, split(/(？\」|。\」|！\」|。(?!\」))/, $text);

        while (my @vals = $iter->()) {
            local $_ = join "", @vals;
            s/( \A\s+ | \s+\Z )//x;
            push @result, $_;
        }

        return @result;
    }

    sub sentences {
        my ($self) = @_;
        my @result;

        my $exclude = $self->exclude;

        my $dom = Mojo::DOM->new( $self->response->decoded_content);

        $dom->find("style, script")->each(sub { $_[0]->replace("<div></div>") });

        $dom->find($self->wanted)->each(
            sub {
                local $_ = $_[0]->all_text(0);
                return if /\A\s*\Z/;
                return if $exclude && /$exclude/;

                for(split /[\r\n]+/) {
                    push @result, __split_to_sentences( $_ );
                }

            }
        );

        return @result;
    }
};

1;
