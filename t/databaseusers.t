#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Test::LongString;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN {
    plan tests => 4;
}

BEGIN { use_ok( 'API::Plesk::DatabaseUsers' ); }

is_string(
    API::Plesk::DatabaseUsers::create(
        'login'     => 'nrg_main',
        'db-id'     => 123,
        'password'  => 'qwerty',
    ),

    '<database><add-db-user><db-id>123</db-id><login>nrg_main</login>' .
    '<password>qwerty</password></add-db-user></database>',

    'API::Plesk::DatabaseUsers::create test'
);


is_string(
    API::Plesk::DatabaseUsers::delete( 'id' => 234 ),
    '<database><del-db-user><filter><id>234</id></filter></del-db-user></database>',
    'API::Plesk::DatabaseUsers::delete by user id test'
);



is_string(
    API::Plesk::DatabaseUsers::delete( 'db-id' => 342 ),
    '<database><del-db-user><filter><db-id>342</db-id></filter></del-db-user></database>',
    'API::Plesk::DatabaseUsers::delete by db-id test'
);



