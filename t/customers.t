#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN { 
    plan tests => 15;

    use_ok('API::Plesk::Customers'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

my $customers = API::Plesk::Customers->new( plesk => $api );

isa_ok($customers, 'API::Plesk::Customers');
