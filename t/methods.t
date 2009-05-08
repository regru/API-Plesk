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
    plan tests => 23;
}

BEGIN { use_ok( 'API::Plesk::Methods' ); }


# construct_request_xml

is_string(
    API::Plesk::Methods::construct_request_xml(
        'client-template',
        'get', 111
    ),

    "<client-template><get>111</get></client-template>",

    'construct_request_xml'
);


is_string(
    API::Plesk::Methods::construct_request_xml(
        'client-template',
        'get'
    ),
    '<client-template><get/></client-template>',
    'construct_request_xml'
);


ok( 
    ! API::Plesk::Methods::construct_request_xml('test'), 
    'construct_request_xml'
);

# Generate_settings_block

is_string( 
    API::Plesk::Methods::generate_settings_block('permission'),
    '<permissions/>', 'blank permission query to generate_settings_block'
);


is_string( 
    API::Plesk::Methods::generate_settings_block ('limit'),
    '<limits/>', 'blank limit query to generate_settings_block'
);


is_string( 
    API::Plesk::Methods::generate_settings_block(
        'limit', 
        key1  => 'value1',
        key2  => 'value2',
    ),
    '<limits><limit><name>key1</name><value>value1</value>' .
    '</limit><limit><name>key2</name><value>value2</value>' . 
    '</limit></limits>',

    'limit query to generate_settings_block'
);

# Generate_limits_block

is_string(
    API::Plesk::Methods::generate_settings_block('limit'),
    '<limits/>', 
    'test auto generated generate_limits_block sub' 
);

# Generate_permissions_block

is_string( 
    API::Plesk::Methods::generate_settings_block('permission'),
    '<permissions/>',
    'test auto generated generate_permissions_block sub' 
);

# Generate_gen_infos

is_string( 
    API::Plesk::Methods::generate_info_block('gen_info'),
    '<gen_info/>',
    'test generate_gen_infos_block (blank)'
);

is_string( 
    API::Plesk::Methods::generate_info_block('gen_info', name => 'Pavel'),
    '<gen_info><name>Pavel</name></gen_info>',
    'test generate_gen_infos_block ( name => Pavel )'
);

# Generate_datasets_block

is_string( 
    API::Plesk::Methods::generate_info_block('dataset'),
    '<dataset/>',
    'test generate_datasets_block ( blank )'
);

is_string( 
    API::Plesk::Methods::generate_info_block('dataset', name => 'Pavel'),
    '<dataset><name>Pavel</name></dataset>',
    'test generate_datasets_block ( name => Pavel )'
);

# Create_filter

is_string( 
    API::Plesk::Methods::create_filter(
        login_field_name => 'login',
        login            => 'userlogin' ), 
    '<filter><login>userlogin</login></filter>',
    'create_filter( userlogin ) check'            
);


is_string( 
    API::Plesk::Methods::create_filter( id => '12345' ), 
    '<filter><id>12345</id></filter>',
    'create_filter( id ) check'            
);


is( 
    API::Plesk::Methods::create_filter( login_field_name => 'login', all => 1 ),
    '<filter/>',
    'create_filter( blank ) check'            
);

# Create_node test

is_string( 
    API::Plesk::Methods::create_node('name', 'Pavel'),
    '<name>Pavel</name>',
    'create_node test'  
);


is_string( 
    API::Plesk::Methods::create_node('name'),
    '<name/>',
    'create_node blank value test'  
);

# xml_extract_values

is_deeply(
    API::Plesk::Methods::xml_extract_values('<key>value</key>'),
    { key => 'value' },
    'test xml_extract_values extract one value'
);


is_deeply(
    API::Plesk::Methods::xml_extract_values('<key>value</key>  
                                                            <key2>value2</key2> '),
    { key => 'value', key2 => 'value2' },
    'test xml_extract_values extract multiple values'
);

# check_required_keys

ok( 
    ! API::Plesk::Methods::check_required_keys("aaa", "bbb"), 
    'blank query to check_required_keys'
);

ok( 
    API::Plesk::Methods::check_required_keys( 
        { key1 => 'val1', key2 => 'val2' }, 
        ['key1', 'key2']
    ), 
    'query (with all required fields) to check_required_keys'
);


ok( 
    ! API::Plesk::Methods::check_required_keys( 
        { key1 => 'val1', key2 => 'val2' }, 
        ['key1', 'key3']
    ), 
    'query (without all required fields) to check_required_keys'
  );

