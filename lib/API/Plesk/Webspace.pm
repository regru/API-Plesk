
package API::Plesk::Webspace;

use strict;
use warnings;

use Carp;
use Data::Dumper;

use base 'API::Plesk::Component';

my @gen_setup_fields = qw(
    name
    owner-id
    owner-login
    owner-guid
    owner-external-id
    htype
    ip_address
    status
    external-id
);


sub add {
    my ( $self, %params ) = @_;
    my $gen_setup = $params{gen_setup} || confess "Required gen_setup parameter!";

    $self->check_hosting(\%params);

    $self->check_required_params(\%params, [qw(plan-id plan-name plan-guid plan-external-id)]);
    $self->check_required_params($gen_setup, qw(name ip_address));

    $params{gen_setup} = $self->sort_params($gen_setup, @gen_setup_fields);

    return 
        $self->plesk->send(
            'webspace', 'add',
            \%params
        );
}

sub get {
    my ($self, %filter) = @_;
    my $dataset = {gen_info => ''};
    
    if ( my $add = delete $filter{dataset} ) {
        $dataset = { map { ( $_ => '' ) } ref $add ? @$add : ($add) };
        $dataset->{gen_info} = '';
    }

    return 
        $self->plesk->send(
            'webspace', 'get', 
            { 
                filter  => @_ > 2 ? \%filter : '',
                dataset => $dataset
            }
        );
}

sub set {
    my ( $self, %params ) = @_;
    my $filter = delete $params{filter} || '';
    
    $self->check_hosting(\%params);

    return
        $self->plesk->send(
            'webspace', 'set',
            {
                filter  => $filter,
                values  => \%params
            }
        );
}

sub del {
    my ($self, %filter) = @_;

    return 
        $self->plesk->send(
            'webspace', 'del',
            { filter  => @_ > 2 ? \%filter : '' }
        );
}

sub add_plan_item {
    my ( $self, %params ) = @_;
    my $filter = delete $params{filter} || '';

    my $name = $params{name} || confess "Required name field!";    

    return
        $self->plesk->send(
            'webspace', 'add-plan-item',
            {
                filter      => $filter,
                'plan-item' => { name => $name }
            }
        );
}


1;
