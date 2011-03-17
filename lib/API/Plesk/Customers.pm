
package API::Plesk::Customers;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

my @gen_info_fields = qw(
    cname
    pname
    login
    passwd
    status
    phone
    fax
    email
    address 
    city 
    state
    pcode
    country 
    owner-id
);

sub add {
    my ( $self, %params ) = @_;
    my $gen_info = $params{gen_info} || confess "Required gen_info parameter!";

    $self->check_required_params($gen_info, qw(pname login passwd));

    return 
        $self->plesk->send(
            'customer', 'add',
            {gen_info => $self->sort_params($params{gen_info}, @gen_info_fields)}
        );
}

sub get {
    my ($self, %filter) = @_;

    return 
        $self->plesk->send(
            'customer',
            'get', 
            { 
                filter => @_ > 2 ? \%filter : '',
                dataset => [ {gen_info => ''}, {stat => ''} ]
            }
        );
}

sub set {
    my ( $self, %params ) = @_;
    my $filter   = $params{filter}   || '';
    my $gen_info = $params{gen_info} || '';

    $gen_info || confess "Required gen_info or stat parameter!";

    return
        $self->plesk->send(
            'customer', 'set',
            {
                filter  => $filter,
                values => {
                    gen_info => $gen_info,
                }
            }
        );
}

sub del {
    my ($self, %filter) = @_;

    return 
        $self->plesk->send(
            'customer',
            'del',
            { filter  => @_ > 2 ? \%filter : '' }
        );
}

1;
