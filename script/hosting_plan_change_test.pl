#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  hosting_plan_change_test.pl
#
#        USAGE:  ./hosting_plan_change_test.pl
#
#  DESCRIPTION:  Предназначен для тестирования возможности миграции между тарифными планами хостинга на новых VDS
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Odintsov (nrg), <nrg@cpan.org>
#      COMPANY:  
#      VERSION:  0.1
#      CREATED:  Птн Апр 25 00:39:24 SAMST 2008
#     REVISION:  ---
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

our ($plesk_url, $password, $user, $host_ip, $api_version);

GetOptions(
    'url=s'	    => \$plesk_url,      # Plesk panel`s url 
    'password|p=s'  => \$password,       # panel pass
    'user|u=s'      => \$user,           # panel login, "admin" -- default
    'hostip|h=s'    => \$host_ip,
    'api|a=s'       => \$api_version,
);

$user ||= 'admin';
$api_version ||= '1.5.0.0';

die "Not enought params" unless (
    $plesk_url  &&
    $password    &&
    $user        &&
    $host_ip     &&
    $api_version
);

# Введём индексы тарифных планов
my %plan_ids = map { $_ => $a++ } qw(Mail-1 Mail-2 Host-1 Host-2 Host-3);

# Характеристики наших тарифов, указанные на сайте
# Тарифы будут даны в последовательности Mail-1, Mail-2, Host-1, Host-2, Host-3
my $settings = {
    limits => {
        max_db          => [ 0, 0, 10, 20, 30 ],            # почтовые ящики
        disk_space      => [ 
            qw(
                157286400
                314572800
                2097152000
                4000
                6000
            ) 
        ],
        max_maillists   => [ 5, 5, 10, 20, 30 ],
        max_dom         => [ 1, 1, 10, 20, 30 ],            # число сайтов
        max_box         => [ qw(5 -1 -1 -1 -1) ],
        max_resp        => [ (-1) x 5 ],
    },


    permissions => {
        manage_php_safe_mode => [ 'false', 'false', 'true', 'true', 'true' ],
        cp_access            => [ ('true') x 5 ],
        manage_crontab       => [ 'false', 'false', 'true', 'true', 'true' ],
        manage_spamfilter    => [ ('true') x 5 ],
        manage_virusfilter   => [ ('true') x 5 ],
    }
};

# Это зарезервированные имена пользователей и доменов
# Они НЕ могут использоваться нигде, кроме данного теста :)
my %test_data = (
    Host => { 
        username => 'hosting_test1',
        domain   => 'hosting-test1.ru',
        plan     => 'Host-1',
        id       => 0, 
    },

    Mail => { 
        username => 'mail_test1',
        domain   => 'mail-test1.ru',
        plan     => 'Mail-1',
        id       => 0, # номер в Плеске
    },
);

# Подключаемся к Плеску
my $plesk = API::Plesk->new(
    api_version   => $api_version,
    username      => $user,
    password      => $password,
    url           => $plesk_url,
);

# Создаём тестовые аккаунты, на которых далее будем эксперементировать

foreach my $test_account (keys %test_data) {

    my $plan      = $test_data{$test_account}->{plan};
    my $domain    = $test_data{$test_account}->{domain};
    my $user_name = $test_data{$test_account}->{username};


    my $get_result = $plesk->Accounts->get( login => $user_name );

    if ($get_result->is_success) {
        # Удалим аккаунт, если он существует
        my $del_result = $plesk->Accounts->delete( login => $user_name );
        die "Del account failed:" . $del_result->get_error_string unless $del_result->is_success;
    }

    my $create_account_result = $plesk->Accounts->create( 
        general_info    => {
            passwd          => 'my_pass',
            pname           => $user_name,
            login           => $user_name,
            phone           => '+4951234567',
            email           => 'null@nrg.name',
            country         => 'RU',
        },
        'template-name' => $plan
    );

    if ($create_account_result->is_success) { 
         my $add_domain_result = $plesk->Domains->create(
            dname        => $domain,
            client_id    => $test_data{$test_account}->{id} = $create_account_result->get_id,
            ip           => $host_ip,
            ftp_login    => $user_name,
            ftp_password => 'ftp_pass',
            template     => $plan,
        );

        if ($add_domain_result->is_success) {
            print "Успешно создали аккаунт для $domain\n";
        } else {
            die "Add domain failed: " . $add_domain_result->get_error_string;;
        }
    } else {
        die "Create Account failed: " . $create_account_result->get_error_string;
    }
}

#  сейчас имеем два аккаунта на тарифных планах Host-1 и Mail-1


# сверим данные созданных аккаунтов с эталонными
foreach my $test_account (keys %test_data) {
    validate($test_data{$test_account}); # начаьная проверка параметров вновь созданного акка


    if ($test_data{$test_account}->{plan} eq 'Host-1') {
        # хостинговый
        change_plan_and_validate($test_data{$test_account}, 'Host-2', 'Host-3');
    } else {
        # почтовый
        change_plan_and_validate($test_data{$test_account},'Mail-2');
    }
}


sub change_plan_and_validate {
    my ($test_account, @new_plans)= @_;

    foreach my $new_plan (@new_plans) {
        my $change_plan_result = API::Plesk::Complex::change_tariff(
            $plesk, 
            from => $test_account->{plan},
            to   => $new_plan,
            id   => $test_account->{id} 
        );

        die 'Change plan failed: ' . $change_plan_result->get_error_string
            unless ($change_plan_result->is_success);
        
        print "Смена тарифа с $test_account->{plan}  на $new_plan прошла успешно\n";
        $test_account->{plan} = $new_plan;

        validate($test_account);
    }
}


sub validate {
    my $test_account = shift;

    my $details = $plesk->Accounts->get(
        login       => $test_account->{username},
        limits      => 1,
        permissions => 1 
    );

    if ($details->is_success) {
        if (ref $details->get_data->[0]->{data}          eq 'HASH'   &&
            ref $details->get_data->[0]->{permissions}   eq 'HASH'   &&
            ref $details->get_data->[0]->{limits}        eq 'HASH'
        ) {
            my $data = $details->get_data->[0]->{data};
            my $permissions = $details->get_data->[0]->{permissions};
            my $limits = $details->get_data->[0]->{limits};

            # проверим лимиты
            for (sort keys %{ $settings->{limits} } ) {
                if (
                    ($a = $limits->{$_}) eq 
                    ($b = $settings->{limits}->{$_}->[$plan_ids{$test_account->{plan}}]) 
                ) {
                    1; # all ok!
                } else {
                    die "Difference! Param: $_, account: $test_account->{username}," .
                        "plan: $test_account->{plan} (Got: $a. Expected: $b)";
                }   
            }
            
            # проверим ограничения
            for (sort keys %{ $settings->{permissions} }) {
                if ( 
                    ($a = $permissions->{$_}) eq 
                    ($b = $settings->{permissions}->{$_}->[$plan_ids{$test_account->{plan}}]) 
                ) {
                    1; # all ok!
                } else {
                    die "Difference! Param: $_, account: $test_account->{username}," .
                        "plan: $test_account->{plan} (Got: $a. Expected: $b)";
                }   
            }


        } else {
            die "Get data failed!";
        }
        # $testaccount->{plan} -- текущий план
        # прогоняем все ключи, имеющиеся в "эталоне" и выбрасываем ошибку,
        # если переданный аккаунт имеет отличные данные
        # $settings
        #
    } else {
        die $details->get_error_string;
    }
}
