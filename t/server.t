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
    use_ok('API::Plesk::Server');
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

my $server = API::Plesk::Server->new( plesk => $api );

isa_ok($server, 'API::Plesk::Server');

isa_ok($api->server, 'API::Plesk::Server');

is_deeply(
    $server->set(password => 1, bulk_send => 1),
    { password => 1 },
    'set'
);
