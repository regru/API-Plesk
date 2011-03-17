
package API::Plesk::Webspaces;

use strict;
use warnings;

use Carp;

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
    my $gen_info = $params{gen_setup} || confess "Required gen_setup parameter!";

    $self->check_required_params(\%params, [qw(plan-id plan-name plan-guid plan-external-id)]);
    $self->check_required_params($gen_info, qw(pname login passwd));

    $params{gen_info} = $self->sort_gen_info($params{gen_info});

    return 
        $self->plesk->send(
            'webspace', 'add',
            \%params
        );
}

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

sub del {
    my ($self, %filter) = @_;

    return 
        $self->plesk->send(
            'webspace', 'del',
            { filter  => @_ > 2 ? \%filter : '' }
        );
}

1;
