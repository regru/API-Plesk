#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN {
    plan tests => 4;
    use_ok('API::Plesk::DNS');
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

my $dns = API::Plesk::DNS->new( plesk => $api );

isa_ok($dns, 'API::Plesk::DNS');

isa_ok($api->dns, 'API::Plesk::DNS');

is_deeply(
    $dns->get_soa(id => 1, bulk_send => 1),
    {
        filter  => { id => 1 },
        soa     => '',
    },
    'get_soa'
);
