#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN {
    plan tests => 32;
}

BEGIN { use_ok( 'API::Plesk::Response' ); }


##
## API::Plesk::Response tests
##

my @error_codes_for_test = (int rand 1000, int rand 500);

isa_ok( 
    API::Plesk::Response->new( 'answer', @error_codes_for_test ),
    'API::Plesk::Response',
    'test new' 
);


foreach my $answer ('answer', '') {
    my $answer_state = $answer ? 'with' : 'without';
    
    foreach my $error ('', $error_codes_for_test[1], \@error_codes_for_test) {
        my $error_state;
        my @test_mas;

        if (ref $error eq 'ARRAY' ) {

            @test_mas = @$error;
            $error_state = 'with multiple errors';

        } elsif (length $error > 0) {

            @test_mas = $error;
            $error_state = 'with one error';

        } else {

            $error_state = 'without errors';

        }

        my $response =  API::Plesk::Response->new($answer, @test_mas);

        is_deeply( 
            $response->get_error_string,
            (join ', ', @test_mas), 
            "get_error_string $error_state, $answer_state answer"
        );
        
        is_deeply( 
            scalar $response->get_error_codes, 
            scalar @test_mas > 0 ? [ @test_mas ] : '', 
            "get_error_codes (scalar context) $error_state, $answer_state answer"
        );

        my @result_error_codes = $response->get_error_codes;
                
        is_deeply( 
            \@result_error_codes, 
            \@test_mas, 
            "get_error_codes (list context) $error_state, $answer_state answer"
        );

        is( $response->is_success, $error || !$answer ? '' : 1, 'is_success test' );
        
        is( 
            $response->get_data, 
            $error || !$answer ? '' : $answer, 
            'get_data method test' 
        );
    }
}

