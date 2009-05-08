use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN {
    plan tests => 7;
}

BEGIN { use_ok( 'API::Plesk' ); }

#
# Tests with Fake response
#

my $plesk_client = API::Plesk->new( %TestData::plesk_valid_params );

my $valid_answer_without_errors = <<XML;
<?xml version="1.0"?>
<packet version="1.5.2.0">
    <client> 
        <add> 
            <result> 
                <status>ok</status> 
                <id>24</id> 
            </result> 
            <result> 
                <status>ok</status> 
                <id>12</id> 
            </result> 
        </add> 
    </client> 
</packet>
XML

$plesk_client->{'fake_response'} = $valid_answer_without_errors;

is_deeply( 
    $plesk_client->Accounts->create( )->get_data, 
    [
        { status => 'ok', id => 24 },
        { status => 'ok', id => 12 },
    ], 
    'checking get_xml on valid xml'
);

ok( 
    $plesk_client->Accounts->create( )->is_success,  
    'checking is_success valid xml'
);

$plesk_client->{'fake_response'}  = '';

my $multiple_errors_in_one_respond = <<XML;
<?xml version="1.0"?>
<packet version="1.5.2.0"> 
    <client>
        <add> 
            <result> 
                <status>error</status> 
                <errcode>1027</errcode> 
                <errtext>IP operation failed.</errtext> 
                <id>24</id> 
                <name>base_template</name> 
            </result>
            <result>
                <status>error</status> 
                <errcode>1023</errcode> 
                <errtext>Operation failed.</errtext> 
                <id>12</id>
                <name>quick_template</name> 
            </result> 
        </add>
    </client> 
</packet>
XML


$plesk_client->{'fake_response'} = $multiple_errors_in_one_respond;

is_deeply( 
    scalar $plesk_client->
    Accounts->create( )->get_error_codes, 
    [ '1027: IP operation failed.', '1023: Operation failed.' ], 
    'checking multiple errors in xml'
);

ok(
    ! $plesk_client->Accounts->create( )->is_success,
    'check result of error response' 
);

$plesk_client->{'fake_response'}  = '';

my $error_and_success_res_in_one_respond = <<XML;
<?xml version="1.0"?>
<packet version="1.5.2.0"> 
    <client>
        <add> 
            <result> 
                <status>error</status> 
                <errcode>1027</errcode> 
                <errtext>IP operation failed.</errtext> 
                <id>24</id> 
                <name>base_template</name> 
            </result>
            <result>
                <status>ok</status> 
                <id>12</id>
                <name>quick_template</name> 
            </result> 
        </add>
    </client> 
</packet>
XML


$plesk_client->{'fake_response'} = $error_and_success_res_in_one_respond;

is_deeply( 
    scalar $plesk_client->Accounts->create( )->get_error_codes, 
    [ '1027: IP operation failed.' ], 
    'checking response with errors  and success result'
  );

ok(
    ! $plesk_client->Accounts->create( )->is_success,
    'check result of error response' 
);

$plesk_client->{'fake_response'} = '';
