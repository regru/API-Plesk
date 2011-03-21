#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;
use XML::Fast;

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
        response  => xml2hash('
<?xml version="1.0" encoding="UTF-8"?>
<packet>
    <customer>
        <get>
            <result>
                <status>ok</status>
                <id>123</id>
                <guid>123456</guid>
                <data>
                    <test>qwerty</test>
                </data>
            </result>
        </get>
    </customer>
</packet>', array => ['get', 'result'])
);
ok($res->is_success);
is($res->id, 123);
is($res->guid, 123456);
is($res->result->{status}, 'ok');
is($res->data->{test}, 'qwerty');
