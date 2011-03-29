use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN {
    plan tests => 5;
}

BEGIN {
    use_ok( 'API::Plesk::Component' );
}

my $c = API::Plesk::Component->new(
    plesk => API::Plesk->new(%TestData::plesk_valid_params)
);

eval {
    $c->check_required_params({ test => 123}, qw(test));
};
ok(!$@);

eval {
    $c->check_required_params({ test => 123, test2 => 123}, [qw(test ddd)]);
};
ok(!$@);

eval {
    $c->check_required_params({ test => 123}, qw(qqq));
};
like($@, qr/Required field qqq!/);

eval {
    $c->check_required_params({ test => 123}, [qw(qqq ff)]);
};
like($@, qr/Required any of this fields: qqq, ff!/);

is_deeply(
    $c->sort_params({key => 1, key2 => 2, key3 => 3, key4 => 4}, [qw(key3 key2)], 'key'),
    [
        {key3 => 3},
        {key  => 1},
    ]
);

