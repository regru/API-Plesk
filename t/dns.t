#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN {
    plan tests => 7;
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

is_deeply(
    $dns->upd_soa(
        id => 2,
        bulk_send => 1,
        ttl => 300,
        minimum => 150,
    ),
    {
        filter  => { id => 2 },
        soa     => {
            ttl => 300,
            minimum => 150,
        },
    },
    'upd_soa.1'
);

is_deeply(
    $dns->upd_soa(
        id => 2,
        bulk_send => 1,
        retry => 3600,
    ),
    {
        filter  => { id => 2 },
        soa     => {
            retry => 3600,
        },
    },
    'upd_soa.2'
);

is_deeply(
    $dns->upd_soa(
        id => 2,
        bulk_send => 1,
        retry => 3600,
        ttl => 300,
        minimum => 150,
        expire => 604800,
        refresh => 10800,
    ),
    {
        filter  => { id => 2 },
        soa     => {
            retry   => 3600,
            ttl     => 300,
            minimum => 150,
            expire  => 604800,
            refresh => 10800,
        },
    },
    'upd_soa.3'
);
