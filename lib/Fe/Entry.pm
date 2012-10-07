package Fe::Entry;

use Elastic::Doc;
use DateTime;

has url => (
    is => "ro",
    isa => "Str",
    required => 1,
    unique_key => "entry_url"
);

has feed => (
    is => "ro",
    isa => "Str",
    required => 1,
    type => 'string'
);

has title => (
    is => "ro",
    isa => 'Str',
    required => 1,
);

has content => (
    is => "ro",
    isa => 'Str',
    required => 1,
);

has created_at => (
    is => "ro",
    isa => "DateTime",
    default => sub { DateTime->now }
);

no Elastic::Doc;
1;
