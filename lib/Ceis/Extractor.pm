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
        required => 1
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
    };

    sub _build_response {
        state $ua = Mojo::UserAgent->new;

        my ($self) = @_;
        die unless $self->url;
        return $ua->get($self->url)->res;
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

                s/[\r\n]//g;
                push @result, __split_to_sentences( $_ );
            }
        );

        return @result;
    }
};
1;

