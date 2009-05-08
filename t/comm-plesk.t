#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

my $allow_plesk_onlite_tests;
my %data_accumulator_for_online_tests;


BEGIN {
    $allow_plesk_onlite_tests = $ENV{'online'};

    plan tests => 36;
}

BEGIN {
    use_ok( 'API::Plesk' );
    use_ok( 'API::Plesk::Response' );
}


# Before start:
# CREATE TEMPLATE in Plesk and fill this fields:

##
## API::Plesk
##

SKIP: {
    skip "This test require internet connection! See README", 34 if !$allow_plesk_onlite_tests;

    my $new_plesk_client = API::Plesk->new(%TestData::online_plesk_valid_params);
    my $plesk_client = API::Plesk->new(%TestData::online_plesk_valid_params);

    # Del all accounts before tests

    ok( 
        $new_plesk_client->Accounts->delete( all => 1 )->is_success,
        'All accounts delete check'
    );

    create_work_logins($new_plesk_client, \%data_accumulator_for_online_tests);

    is_deeply(
        scalar $new_plesk_client->Accounts->create( 
            general_info    => create_unique_user_data('crby_login'),
            'template-name' => $TestData::online_manual_created_template_name
        )->get_error_string,
    
        '1007: Unable to set "pname" argument\'s value ("testuser_crby_login"): '.
        'Client with name testuser_crby_login already exists.',
        'Create dublicate account test -- 1007 error (account already exists)'
    );


    # Delete accounts test

    is_deeply( 
        $new_plesk_client->Accounts->delete( 
            id => $data_accumulator_for_online_tests {user_id_from_create_with_tmpl_id}
        )->is_success,
    
        1,
        'Delete exist account by id'
    );

    is_deeply( 
        $new_plesk_client->Accounts->delete( 
            login => create_unique_user_data('crby_login')->{login},
        )->is_success,
      
        1,
        'Delete exist account by login'
    );

    create_work_logins($new_plesk_client, \%data_accumulator_for_online_tests); # recreate accounts

    delete_all_accounts($plesk_client);

    is_deeply( 
        $new_plesk_client->Accounts->delete( 
            login => 'sasdaad'
        )->get_error_string,
     
        '1013: client does not exist',
        'Delete non exists account'
    );

    # Get account info tests

    is_deeply(
        $new_plesk_client->Accounts->get( all => 1)->is_success,
        1,
        'Get info by all logins (but it not present)'
    );

    create_work_logins($new_plesk_client, \%data_accumulator_for_online_tests); # recreate two accounts

    is_deeply(
        $new_plesk_client->Accounts->get( login => 'aaabbbcccddd')->get_error_string,
        '1013: client does not exist',
        'Get info by non exists login'
    );


    ok(
        _compare(
            $new_plesk_client->Accounts->get( 
                login => create_unique_user_data('crby_login')->{'login'}
            ) -> get_data->[0]->{'data'}, 

            create_unique_user_data('crby_login'),
        ),

        'Get account info by login'
    );

    ok(
        _compare ($new_plesk_client->Accounts->get(
                id => $data_accumulator_for_online_tests {user_id_from_create_with_tmpl_id}
            )->get_data->[0]->{'data'},
            create_unique_user_data('createby_id'),
        ),
        'Get account info by id'
    );


    my $query_result      = $new_plesk_client->Accounts->get( all => 1 );
    my $first_user_data   = $query_result->get_data->[0]->{'data'};
    my $second_user_data  = $query_result->get_data->[1]->{'data'};

    ok(
        _compare($first_user_data, create_unique_user_data('crby_login')) &&
        _compare($second_user_data, create_unique_user_data('createby_id')),   
        'Get all account users account info'
    );

    # modify account tests

    ok( $new_plesk_client->Accounts->modify(
            login     => create_unique_user_data('crby_login')->{'login'}, 
            new_data  => { phone => '7777777'}
    )->is_success,
       
    'Modify one account info field'
    );

    ok(
        ! $new_plesk_client->Accounts->modify(
            login     => 'abdeffaa', 
            new_data  => { phone => '7777777'}
        )->is_success,
    
        'Modify fields of non exist account'
    );


    is_deeply(       
        $new_plesk_client->Accounts->get(
            login =>  create_unique_user_data('crby_login')->{'login'} )
                ->get_data->[0]->{'data'}->{'phone'},
        7777777,
        'Check modified account info'
    ); 


    ok(
        $new_plesk_client->Accounts->modify(
            all => 1, 
            new_data  => { 
                phone => '55555',
                city  => 'Samara'
            }
            )->is_success,

        'Modify multiple account info fields'
    );

    my $set_multiple_data_response =  $new_plesk_client->Accounts->get( all => 1 );

    my $result_modify_all;

    if ($set_multiple_data_response->get_data->[0]->{'data'}{'phone'} eq '55555' &&
        $set_multiple_data_response->get_data->[1]->{'data'}{'phone'} eq '55555') {
    
        if ($set_multiple_data_response->get_data->[0]->{'data'}{'city'} eq 'Samara' &&
            $set_multiple_data_response->get_data->[1]->{'data'}{'city'} eq 'Samara') {
            $result_modify_all = 1;
        }
    }


    ok($result_modify_all,'Check modify info on multiple accounts'); 
    delete_all_accounts($new_plesk_client); # delete all accounts after test

    my $result_template_get_query;
    ok(
        ($result_template_get_query = $new_plesk_client->Templates->get(
           name => $TestData::online_manual_created_template_name,
            type => 'account'
        ))->is_success,
    'Templates_get query'
    );


    is(
        (scalar grep /ip-pool|permissions|limits/, sort keys %{$result_template_get_query->get_data->[0]}),
        3, 
        'Templates_get->get_data query'
    );


    ##
    ## Plesk::Domains online tests
    ##

    delete_all_accounts($plesk_client);
    create_work_logins($new_plesk_client, \%data_accumulator_for_online_tests);

    my $result_template_get_ip_query = $plesk_client->Templates->get(
        name => $TestData::online_manual_created_template_name,
        type => 'account'
    );

    my ($server_ip_for_tests) = ($result_template_get_ip_query->get_data->[0]->{'ip-pool'}
        =~ m#<ip-address>(\d+\.\d+\.\d+\.\d+)</ip-address>#g);

    my $domain_id = 0;

    like(
        $domain_id = $new_plesk_client->Domains->create(
            dname           => 'yandex.ru',
            ip              => $server_ip_for_tests,
            client_id       => $data_accumulator_for_online_tests {user_id_from_create_with_tmpl_name},
            ftp_login       => 'asdasdad',
            ftp_password    => 'qwertsdasy',
            template        => $TestData::online_manual_created_template_name,
        )->get_id,
        qr/\d+/,
        'Domains_create test'
    );
    
    my $add_db_res = $new_plesk_client->Databases->create(
        'name'          => 'my_new_base',
        'domain-id'     => $domain_id,
        'type'          => 'mysql',
        'db-server-id'  => 1,
    );

    like($add_db_res->get_id, qr/\d+/, 'Add db to domain ');

    my $add_user_to_db_result = $new_plesk_client->DatabaseUsers->create(
        'login'     => 'nrg_main',
        'db-id'     => $add_db_res->get_id,
        'password'  => 'qwerty',
    );

    like( $add_user_to_db_result->get_id, qr/\d+/, 'Add user to db' );

    # db & db user present in Plesk at this moment ;)

    # del user by id
    my $del_db_user_res = $new_plesk_client->DatabaseUsers->delete(
        'id' => $add_user_to_db_result->get_id,
    );

    ok( $del_db_user_res->is_success, 'Del db user by id from domain' );

    
    # del db by db-id
    my $del_db_res = $new_plesk_client->Databases->delete(
        'db-id' => $add_db_res->get_id,
    );

    ok( $del_db_res->is_success, 'Del db by db-id from domain');


    is_deeply(
        $new_plesk_client->Domains->create(
            dname => 'yandex.ru',
            ip => $server_ip_for_tests,
            client_id =>  $data_accumulator_for_online_tests {user_id_from_create_with_tmpl_name},
            ftp_login => 'asdasdad',
            ftp_password => 'qwertsdasy',
            template        => $TestData::online_manual_created_template_name,
        )->get_error_string,
        '1007: Domain adding was failed. Error: Domain yandex.ru already exists.',
        'Domains_create test -- add dublicate domain'
    );
} # end of SKIP

