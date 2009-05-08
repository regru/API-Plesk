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
    plan tests => 3;
}

BEGIN {
    use_ok( 'API::Plesk::Templates' );
}   

##
## Plesk::Templates tests.
##

is_string ( 
    API::Plesk::Templates::get( name => 'tariff1', type => 'account' ),

    '<client-template><get><filter><name>tariff1</name></filter><limits/>' . 
    '<permissions/><ip-pool/><preferences/></get></client-template>',

    'Templates::get by name test'
);


is_string ( 
    API::Plesk::Templates::get( id => 55555, type => 'account' ),

    '<client-template><get><filter><id>55555</id></filter><limits/>' . 
    '<permissions/><ip-pool/><preferences/></get></client-template>',

    'Templates::get by id test'
);


