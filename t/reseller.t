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
    use_ok('API::Plesk::Reseller');
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

my $reseller = API::Plesk::Reseller->new( plesk => $api );

isa_ok($reseller, 'API::Plesk::Reseller');

isa_ok($api->reseller, 'API::Plesk::Reseller');

is_deeply(
    $reseller->get(id => 1, bulk_send => 1),
    {
        filter => {id => 1},
        dataset => [
	        {gen_info       => ''},
    	    {stat           => ''},
        	{permitions     => ''},
        	{limits         => ''},
        	{ippool         => ''},
        	{subsccriptions => ''},
        ]
    },
    'get'
);
