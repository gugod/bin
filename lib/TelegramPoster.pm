package TelegramPoster;
use v5.18;
use warnings;
use WWW::Telegram::BotAPI;

sub new {
    my $class = shift;
    my %args  = @_;
    my $bot = WWW::Telegram::BotAPI->new( token => $args{token});
    my $tx = $bot->api_request('getMe');
    $tx = $bot->api_request('getUpdates', { offset => 0 });
    return bless { bot => $bot, chat_id => $args{chat_id} }, $class;
}

sub post {
    my ($self, $content) = @_;
    $self->{bot}->api_request(
        sendMessage => {
            chat_id => $self->{chat_id},
            text    => $content
        }
    );
    return $self;
}

1;
