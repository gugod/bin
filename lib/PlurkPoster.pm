package PlurkPoster;
use Object::Tiny qw(username password);
use WWW::Mechanize;

sub post {
    my ($self, $content) = @_;
    my $ua = WWW::Mechanize->new;
    $ua->get('http://www.plurk.com/m/login');
    $ua->submit_form(with_fields => { username => $self->username, password => $self->password });
    $ua->submit_form(with_fields => { content =>  $content });
}

1;
