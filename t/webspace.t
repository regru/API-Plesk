#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN { 
    plan tests => 5;
    use_ok('API::Plesk::Webspace'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

isa_ok($api->webspace, 'API::Plesk::Webspace');

is_deeply(
    $api->webspace->add_subscription(
        'plan-guid' => 'wervqwef',
        bulk_send   => 1
    ),
    [
        {'plan-guid' => 'wervqwef'},
    ]
);

is_deeply(
    $api->webspace->remove_subscription(
        filter      => {'owner-name' => 'qwerty'},
        'plan-guid' => 'wervqwef',
        bulk_send   => 1
    ),
    [
        {filter      => {'owner-name' => 'qwerty'}},
        {'plan-guid' => 'wervqwef'},
    ]
);


is_deeply(
    $api->webspace->switch_subscription(
        filter      => {'owner-name' => 'qwerty'},
        'plan-guid' => 'wervqwef',
        bulk_send   => 1
    ),
    [
        {filter      => {'owner-name' => 'qwerty'}},
        {'plan-guid' => 'wervqwef'},
    ]
);
        
