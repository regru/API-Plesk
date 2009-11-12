#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  hosting_plans_diff.pl
#
#        USAGE:  ./hosting_plans_diff.pl
#
#  DESCRIPTION:  Предназначен для показа различий между тарифными планами Плеска
#
#       AUTHOR:  Pavel Odintsov (nrg), <nrg@cpan.org>
#      COMPANY:  
#      VERSION:  0.1
#      CREATED:  Птн Апр 25 00:39:24 SAMST 2008
#===============================================================================

use strict;
use warnings;

use lib qw(/www/srs/lib);

use Data::Dumper;
use Getopt::Long;
use Carp;

use API::Plesk;
use API::Plesk::Response;
use API::Plesk::Complex;

our ($plesk_url, $password, $user, $host_ip, $api_version, $plan1, $plan2);

GetOptions(
    'url=s'	    => \$plesk_url,      # Plesk panel`s url 
    'password|p=s'  => \$password,       # panel pass
    'user|u=s'      => \$user,           # panel login, "admin" -- default
    'hostip|h=s'    => \$host_ip,
    'api|a=s'       => \$api_version,
    'plan1=s'       => \$plan1,
    'plan2=s'       => \$plan2,
);

$user ||= 'admin';
$api_version ||= '1.5.0.0';

die "Not enought params" unless (
    $plesk_url   &&
    $password    &&
    $user        &&
    $host_ip     &&
    $api_version &&
    $plan1       &&
    $plan2
);

# Подключаемся к Плеску
my $plesk = API::Plesk->new(
    api_version   => $api_version,
    username      => $user,
    password      => $password,
    url           => $plesk_url,
);


my %plans_data;

for ($plan1, $plan2) {
    my $get_account_data_result = $plesk->Templates->get( type => 'account', name => $_  );
    
    if ($get_account_data_result->is_success) {
        for my $block_type ('permissions', 'limits') {
            $plans_data{$_}->{$block_type} = $get_account_data_result->get_data->[0]->{$block_type};
        }
    } else {
        die "Get data for plan $_ failed!\n";
    }
}


for my $type (keys %{ $plans_data{$plan1} }) {
    print "Checking ${type}\t$plan1 : $plan2\n";
    
    for my $key (keys % { $plans_data{$plan1}->{$type} }) {
        unless ( ($a = $plans_data{$plan1}->{$type}->{$key}) eq ($b = $plans_data{$plan2}->{$type}->{$key}) ) {
            print "$key: \t $a \t $b \n";
        }
    }
}
