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

    plan tests => 11;
}

BEGIN {
    use_ok( 'API::Plesk' );
    use_ok( 'API::Plesk::Response' );
    use_ok( 'API::Plesk::Complex' );
}

SKIP: {

    skip "This test require internet connection! See README", 8 if !$allow_plesk_onlite_tests;

    #
    # Tests for tariff change!
    #

    my $new_plesk_client = API::Plesk->new(%TestData::online_plesk_valid_params);

    delete_all_accounts($new_plesk_client);
    create_work_logins($new_plesk_client, \%data_accumulator_for_online_tests);

    is_deeply(
        API::Plesk::Complex::change_tariff(
            $new_plesk_client,
            from    => $TestData::online_new_tariff_name,
            to      => $TestData::online_manual_created_template_name,
            id      => $data_accumulator_for_online_tests {user_id_from_create_with_tmpl_name},
        )->get_error_string,
        'Error, new limit < source limit!',
        'Change account tariff with error query !'
    );


    ok(
        API::Plesk::Complex::change_tariff(
            $new_plesk_client,
            from    => $TestData::online_manual_created_template_name,
            to      => $TestData::online_new_tariff_name,
            id      => $data_accumulator_for_online_tests {user_id_from_create_with_tmpl_name},
        )->is_success,
        'Change account tariff!'
    );


    is_deeply(
        API::Plesk::Complex::change_tariff(
            $new_plesk_client,
            from    => $TestData::online_manual_created_template_name,
            to      => $TestData::online_new_tariff_name,
        )->get_error_string,
        'Not enought data for tariff change!',
        'Try to change tariff without user_id'
    );


    is_deeply(
        API::Plesk::Complex::change_tariff(
            $new_plesk_client,
            from    => 'some_tarif_34234',
            to      => $TestData::online_new_tariff_name,
            id      => $data_accumulator_for_online_tests {user_id_from_create_with_tmpl_name},
        )->get_error_string,
        'Get source template data failed',
        'Change account tariff form non exists tariff!'
    );


    is_deeply(
        API::Plesk::Complex::change_tariff(
            $new_plesk_client,
            from    => $TestData::online_manual_created_template_name,
            to      => 'some_tarif_34234',
            id      => $data_accumulator_for_online_tests {user_id_from_create_with_tmpl_name},
        )->get_error_string,
        'Get result template data failed',
        'Change account tariff to non exists tariff!'
    );
} # SKIP
