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
    plan tests => 5;
}

BEGIN { use_ok( 'API::Plesk::Databases' ); }

is_string(
    API::Plesk::Databases::create(
        'name'          => 'my_new_base',
        'domain-id'     => 555,
        'type'          => 'mysql',
        'db-server-id'  => 1,
    ),

    '<database><add-db><domain-id>555</domain-id>'      . 
    '<name>my_new_base</name><type>mysql</type>'        .
    '<db-server-id>1</db-server-id></add-db></database>',

    'API::Plesk::Databases::create test'
);

is_string(
    API::Plesk::Databases::delete(
        'db-id' => '123123',
    ),
    '<database><del-db><filter><db-id>123123</db-id></filter></del-db></database>',
    'API::Plesk::Databases::delete by db-id test'
);

is_string(
    API::Plesk::Databases::delete(
        'domain-name' => 'yandex.ru', # kill ya.ru :)
    ),
    '<database><del-db><filter><domain-name>yandex.ru</domain-name></filter></del-db></database>',
    'API::Plesk::Databases:delete by domain-name test'
);

is_string(
    API::Plesk::Databases::delete('domain-id' => 123),
    '<database><del-db><filter><domain-id>123</domain-id></filter></del-db></database>',
    'API::Plesk::Databases::delete domain-id test'
);
