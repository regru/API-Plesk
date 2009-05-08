use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN {
    plan tests => 11;
}

BEGIN {
    use_ok( 'API::Plesk' );
}

my $plesk_client = API::Plesk->new( %TestData::plesk_valid_params );

isa_ok( $plesk_client, 'API::Plesk', 'STATIC call new' );

my $yet_another_plesk_client = $plesk_client->new( %TestData::plesk_valid_params );

isa_ok( $plesk_client, 'API::Plesk', 'INSTANCE call new' );
isnt( $plesk_client, $yet_another_plesk_client, 'object compare' );

# check _blank_ query`s to Plesk.pm methods

is_deeply( 
    $plesk_client->plesk_query( q// )->get_error_string, 
    'plesk_query: blank request',
    'blank query to Plesk' 
);

ok(     
    !$plesk_client->plesk_query('')->is_success, 
    'blank query to Plesk' 
);


is_deeply( 
    $plesk_client->plesk_query('test_test')->get_error_string, 
    'plesk_query: no parser subref',
    'blank query to Plesk' 
);

# execute_query

ok( 
    !$plesk_client->_execute_query(''), 
    'Blank low level query to _execute_query, false'
);


# check_xml_answer

is_deeply(  
    $plesk_client->check_xml_answer('')->get_error_string,
    'check_xml_answer: blank query to check_xml_answer',
    'check blank query to check_xml_answer'
);

is_deeply(  
    $plesk_client->check_xml_answer('test_test')->get_error_string,
    'check_xml_answer: no parser subref',
    'check blank query2 to check_xml_answer'
);


# Calling undefined method from Plesk.pm

{
    our $our_warning;
    local $SIG{__DIE__} = sub { $our_warning = shift; }; # confess <=> die
    eval { API::Plesk->new(%TestData::plesk_valid_params)->aaa__bbbccc() };
    like($our_warning, qr/aaa__bbbccc/,
         'Checking AUTOLOAD by calling undefined method.');
}

