
package API::Plesk::Site;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

#TODO
sub add {
    my ( $self, %params ) = @_;
    my $gen_setup = $params{gen_setup} || confess "Required gen_setup parameter!";

    $self->check_hosting(\%params);

    $self->check_required_params(\%params, [qw(plan-id plan-name plan-guid plan-external-id)]);
    $self->check_required_params($gen_setup, qw(name ip_address));


    return 
        $self->plesk->send(
            'webspace', 'add',
            \%params
        );
}

#TODO
sub get {
    my ($self, %filter) = @_;

    my $dataset = delete $filter{dataset} || ['gen_info'];
       $dataset = { map { ( $_ => '' ) } @$dataset };

    return 
        $self->plesk->send(
            'webspace', 'get', 
            { 
                filter  => @_ > 2 ? \%filter : '',
                dataset => $dataset
            }
        );
}

#TODO
sub set {
    my ( $self, %params ) = @_;
    my $filter = delete $params{filter} || '';

    return
        $self->plesk->send(
            'webspace', 'set',
            {
                filter  => $filter,
                values  => \%params
            }
        );
}

#TODO
sub del {
    my ($self, %filter) = @_;

    return 
        $self->plesk->send(
            'webspace', 'del',
            { filter  => @_ > 2 ? \%filter : '' }
        );
}

sub get_physical_hosting_descriptor {
    my ( $self, %filter ) = @_;
    my $bulk_send = delete $filter{bulk_send};
    
    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data :
        $self->plesk->send(
            'site', 
            'get-physical-hosting-descriptor', 
            $data
        );
}

1;
