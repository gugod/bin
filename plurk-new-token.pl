use v5.26;
use Data::Dumper 'Dumper';
use JSON::PP;
use OAuth::Lite::Consumer;

my $JSON = JSON::PP->new->pretty->canonical;

my $_secret = $ARGV[0];
my $secret = do {
    local $/;
    open(my $fh, "<", $_secret) or die $!;
    JSON::PP->new->decode(scalar <$fh>);
};

my $auth = OAuth::Lite::Consumer->new(
    consumer_key    => $secret->{consumer_key},
    consumer_secret => $secret->{consumer_secret},

    site           => 'https://www.plurk.com',
    # realm          => 'https://plurk.com/APP/',

    request_token_path => '/OAuth/request_token',
    access_token_path  => '/OAuth/access_token',
    authorize_path     => '/OAuth/authorize',
);

my $rtoken = $auth->get_request_token();

say $rtoken->token;
say $rtoken->secret;

my $r = $auth->url_to_authorize( token => $rtoken);
say Dumper([ url => $r ]);

say "Verifier: ";
my $verifier = <STDIN>;
chomp($verifier);

my $access_token = $auth->get_access_token(
    token    => $rtoken,
    verifier => $verifier,
);

say Dumper({ access_token => {
    token => $access_token->token,
    secret => $access_token->secret
}});
