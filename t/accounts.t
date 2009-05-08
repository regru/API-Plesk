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
    plan tests => 25;
}

BEGIN { use_ok( 'API::Plesk::Accounts' ); }

##
## API::Plesk::Accounts
##

my $test_user_data = $TestData::test_user_data;

ok(
     ! API::Plesk::Methods::xml_extract_values( ),
     'blank query to xml_extract_values'
);

## client_add_gen_info_check

ok(     
    API::Plesk::Accounts::client_add_gen_info_check( %$test_user_data ),
    'check valid add gen_info by client_add_gen_info_check'
);


ok(     
    ! API::Plesk::Accounts::client_add_gen_info_check(
        %$test_user_data,
        passwd => '11'
    ),
    'check invalid (short pass) add gen_info by client_add_gen_info_check '
);


ok(     
    ! API::Plesk::Accounts::client_add_gen_info_check( login => 'nrg_nnn' ),
    'check invalid (not all flds) gen_info by client_add_gen_info_check '
);

# create test

ok( 
    ! API::Plesk::Accounts::create( ),
    'create account without params' 
);


is_string( 
    API::Plesk::Accounts::create(
        'general_info'    => $test_user_data,
        'template-name'   => 'tarif'
    ),

    "<client><add><gen_info>" . 
    "<country>$test_user_data->{country}</country>" .
    "<email>$test_user_data->{email}</email>".
    "<login>$test_user_data->{login}</login>" .
    "<passwd>$test_user_data->{passwd}</passwd>" .
    "<phone>$test_user_data->{phone}</phone>" . 
    "<pname>pavel</pname></gen_info>"  .
    "<template-name>tarif</template-name></add></client>",

    'create account without params' 
);

# delete test

is_string( 
    API::Plesk::Accounts::delete( all => 1 ),
    '<client><del><filter/></del></client>',
    'generation XML for delete all'
);


is_string( 
    API::Plesk::Accounts::delete( id => 152 ),
    '<client><del><filter><id>152</id></filter></del></client>',
    'generation XML for delete by id'
);


is_string( 
    API::Plesk::Accounts::delete( login => 'nrg' ),
    '<client><del><filter><login>nrg</login></filter></del></client>',
    'generation XML for delete by login'
);


ok( 
    ! API::Plesk::Accounts::delete,
    'generation XML for delete by login (blank args)'
);

# modify test

ok( 
    ! API::Plesk::Accounts::modify( ),
    'generation XML for get all'
);


ok( 
    ! API::Plesk::Accounts::modify( login => 'nrg' ),
    'generation XML (without new data block) for get all'
);


is_string(
    API::Plesk::Accounts::modify( 
        all => 1,
        new_data => { phone => '55555' } 
    ), 
            
    '<client><set><filter/><values><gen_info><phone>55555</phone>' . 
    '</gen_info></values></set></client>',
            
    'generation XML for modify all'
);


is_string( 
    API::Plesk::Accounts::modify( 
        id => 12345,
        new_data => {phone => '55555'}
    ), 

    '<client><set><filter><id>12345</id></filter>' . 
    '<values><gen_info><phone>55555</phone>' .
    '</gen_info></values></set></client>',

    'generation XML for modify elem by id'
);


is_string( 
    API::Plesk::Accounts::modify(
        login => 'nrg_pavel',
        new_data => {phone => '55555'}
    ), 

    '<client><set><filter><login>nrg_pavel</login>' . 
    '</filter><values><gen_info><phone>55555</phone>' .
    '</gen_info></values></set></client>',

    'generation XML for modify elem by login'
);

# get test 

is_string( 
    API::Plesk::Accounts::get( all => 1 ), 
    '<client><get><filter/><dataset><gen_info/></dataset></get></client>',
    'generation XML for get all'
);


is_string( 
    API::Plesk::Accounts::get( login => 'nrg' ),

    '<client><get><filter><login>nrg</login></filter>' . 
    '<dataset><gen_info/></dataset></get></client>',

    'generation XML for get by login'
);

# abstract_parser tests

ok( 
    ! API::Plesk::Accounts::abstract_parser(), 
    'blank request to abstract_parser'
);


is_deeply( 
    API::Plesk::Accounts::abstract_parser(
        'aaa', 
        '<aaa><result><status>fsf</status>' .
        '</result></aaa>', 
        ['status']
    ), 

    { status => 'fsf' },
    'one result block, abstract_parser'
);


is_deeply( 
    API::Plesk::Accounts::abstract_parser(
        'aaa', 
        '<aaa><result><status>error</status>' .
        '</result><result><status>ok' .
        '</status></result></aaa>', 
        ['status']
    ), 
        [ 
            { status => 'error' },
            { status => 'ok' }
        ],
        'multiple result block, abstract_parser'
);


ok( 
    ! API::Plesk::Accounts::abstract_parser(
        'aaa', 
        
        '<aaa><result><status>error'.
        '</status></result><result>' .
        '<status>ok</status></result></aaa>', 
                                       
        [ 'another_status' ]
    ), 
    'error in input data to abstract_parser'
);

# get_response_parse

ok( 
    ! API::Plesk::Accounts::get_response_parse( ),
    'call get_response_parse without args'
);


is_deeply( 
    API::Plesk::Accounts::get_response_parse(<<DOC),
<get>
<result>
<status>ok</status>
<data>
<gen_info><login>nrg</login></gen_info>
</data>
</result>
</get>
DOC
    { 
        status => 'ok',
        data => { login => 'nrg' }
    },     
    'call get_response_parse with one rsult block'
);


is_deeply( 
    API::Plesk::Accounts::get_response_parse(<<DOC),
<get>
<result>
<status>ok</status>
<data>
<gen_info><login>nrg</login></gen_info>
</data>
</result>
<result>
<status>ok</status>
<data>
<gen_info><login>user</login></gen_info>
</data>
</result>

</get>
DOC
    [ 
        { 
            status  => 'ok',
            data    => { login => 'nrg' } 
        }, 
        
        {
            status  => 'ok',
            data    => { login => 'user'}
        }
    ],
    
    'call get_response_parse with multiple result blocks'
);

