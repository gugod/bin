use v5.14;

package Ceis::Extractor {
    use Moose;
    use Mojo::UserAgent;
    use List::MoreUtils qw(natatime);

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
        state $ua = Mojo::UserAgent->new->max_redirects(5);

        my ($self) = @_;
        die unless $self->url;
        return $ua->get($self->url)->res;
    }

    sub _build_wanted {
        state $queries = {
            qr{boingboing\.net/}                 => '.post h2, .post p',
            qr{typepad\.com/}                    => '.entry-header, .entry-body p',
            qr{blogspot\.com/}                   => '.post-title, .post-body',
            qr{theverge\.com/}                   => 'h1.headline, .article-body p',
            qr{gizmag\.com/}                     => 'title, .article_body p',
            qr{http://tw\.myblog\.yahoo\.com/}   => 'h2 span, .msgcontent > :not(.wsharing):not(style):not(script)',
            qr{http://tw\.news\.yahoo\.com/}     => 'h1, .yom-art-content p',
            qr{tw\.nextmedia\.com/[^/]+/article} => "p, .article_paragraph h1, .article_paragraph h2",
        };
        state $url_regexes = [keys %$queries];

        my ($self) = @_;
        die unless $self->url;


        my $query = "p";

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
        my $iter = natatime 2, split(/(？\」|。\」|！\」|。(?!\」))/, $_);
        while (my @vals = $iter->()) {
            $_ = join "", @vals;
            push @result, $_;
        }
        return @result;
    }

    sub sentences {
        my ($self) = @_;
        my @result;

        my $exclude = $self->exclude;

        $self->response->dom($self->wanted)->each(
            sub {
                local $_ = $_[0]->all_text;
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
