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

$res = API::Plesk::Response->new(
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
is($res->id, '');
is($res->guid, '');
is($res->result->[0]->{status}, 'ok');
is($res->data->[0]->{test}, 'qwerty');

$res = API::Plesk::Response->new(
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
is($res->id, '');
is($res->guid, '');
is($res->result->{status}, 'ok');
is($res->data->{test}, 'qwerty');

$res = API::Plesk::Response->new(
        operator  => 'customer',
        operation => 'get',
        response  => xml2hash('
<?xml version="1.0" encoding="UTF-8"?>
<packet>
    <customer>
        <get>
            <result>
                <status>error</status>
                <errcode>123</errcode>
                <errtext>Object not found.</errtext>
            </result>
        </get>
    </customer>
</packet>', array => ['get', 'result'])
);

ok(!$res->is_success);
is($res->id, '');
is($res->guid, '');
is($res->result, undef);
is($res->data, undef);
is($res->error_codes, '123');
is($res->error_texts, 'Object not found.');
is($res->errors, '123: Object not found.');








