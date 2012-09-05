#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN { 
    plan tests => 3;
    use_ok('API::Plesk::ServicePlanAddon'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

isa_ok( $api->service_plan_addon, 'API::Plesk::ServicePlanAddon' );

is_deeply(
    $api->service_plan_addon->get(
        filter => {
            name => 'SiteBuilder',
        },
        'owner-login' => 'shai',
        bulk_send => 1,
    ),
    [
        { filter => { name => 'SiteBuilder' } },
        { 'owner-login' => 'shai' },
    ],
    'get'
);
