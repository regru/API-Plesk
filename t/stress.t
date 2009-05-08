use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

my $allow_plesk_onlite_tests;

BEGIN {
    $allow_plesk_onlite_tests = $ENV{'online'};

    plan tests => 61;
}

BEGIN { use_ok( 'API::Plesk' ); }

##
## Check valid input data to Plesk
#


SKIP: {

    skip "This test require internet connection! See README", 60 if !$allow_plesk_onlite_tests;

    my $plesk_client = API::Plesk->new( %TestData::online_plesk_valid_params );
    
    iterate($TestData::stress_test_data, $plesk_client);

} # SKIP
