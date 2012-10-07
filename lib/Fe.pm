package Fe;
use Elastic::Model;

has_namespace 'feeds' => {
    feed_entry => "Fe::Entry",
};

no Elastic::Model;
1;
