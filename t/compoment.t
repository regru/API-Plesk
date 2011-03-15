use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN {
    plan tests => 2;
}

BEGIN {
    use_ok( 'API::Plesk::Component' );
}

my $c = API::Plesk::Component->new(
    plesk => API::Plesk->new(%TestData::plesk_valid_params)
);

is_deeply( 
    $c->make_request_data(
        'customer', 'add',
        { test => '123'},
        { test => '123'}
    ),
    { customer => [
        { add => {
            test => '123'
        }},
        { add => {
            test => '123'
        }},
    ]}, 'make_request_data'
);
    
