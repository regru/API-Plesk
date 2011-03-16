#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN { 
    plan tests => 15;

    use_ok('API::Plesk::Response'); 
}

isa_ok(
    API::Plesk::Response->new(
        operator  => 'customer',
        operation => 'get',
        response  => {}
    ),
    'API::Plesk::Response'
);

my $res = API::Plesk::Response->new(
        operator  => 'customer',
        operation => 'get',
        response  => {
            customer => [{ 
                get => { 
                    result => {
                        status => 'ok',
                        id => 123,
                        guid => 123456,
                        data => {
                            test => 'qwerty'
                        } 
                    }
                }
            }]
        }
);

ok($res->is_success);
is($res->id, 123);
is($res->guid, 123456);
is_deeply(
    $res->result, 
    {
        status => 'ok',
        id => 123,
        guid => 123456,
        data => {
            test => 'qwerty'
        } 
    }
);
is_deeply(
    $res->data, 
    {
        test => 'qwerty'
    }
);

$res = API::Plesk::Response->new(
        operator  => 'customer',
        operation => 'get',
        response  => {
            customer => [{ 
                get => { 
                    result => {
                        status => 'error',
                        errcode => '123',
                        errtext => 'Object not found.',
                    }
                }
            }]
        }
);

ok(!$res->is_success);
is($res->id, '');
is($res->guid, '');
is($res->result, undef);
is($res->data, undef);
is($res->error_codes, '123');
is($res->error_texts, 'Object not found.');
is($res->errors, '123: Object not found.');








