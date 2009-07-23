#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Test::LongString;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN {
    plan tests => 1;
}

BEGIN { use_ok( 'API::Plesk::DomainAliases' ); }

##
## API::Plesk::DomainAliases
##
