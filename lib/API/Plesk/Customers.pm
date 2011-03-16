
package API::Plesk::Customers;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

=head1 NAME

API::Plesk::Accounts - extension module for the management of user accounts.

=head1 SYNOPSIS

Directly not used, calls via API::Plesk.

 use API::Plesk;

 my $plesk_client = API::Plesk->new(%params);
 # See documentations for API::Plesk

 my $res1 = $plesk_client->Accounts->get(
    id => 36341
 );


=head1 DESCRIPTION

The module provides full support operations with accounts.

=head1 EXPORT

None by default.

=head1 METHODS

=over 3

=cut

=item create(%params)

Creates a user account on the basis of the template.

Params:

Return: response object with created account id in data filed.

=cut
sub add {
    my ( $self, %params ) = @_;
    my $gen_info = $params{gen_info} || confess "Required gen_info parameter!";

    $self->check_required_params($gen_info, qw(pname login passwd));

    return 
        $self->plesk->send(
            'customer', 'add',
            { gen_info => $gen_info }
        );
}

=item modify(%params)

Changes the parameters account.

Params:
limits, permissions, new_data -- hashref`s with corresponding blocks.

And also one of the following options:

  all   => 1      - for all accounts.
  login => 'name' - for a given login.
  id    => 123    - for a given id 

=cut

# Modify element
# STATIC
sub set {
    my ( $self, %params ) = @_;
    my $filter   = $params{filter}   || '';
    my $gen_info = $params{gen_info} || '';
    my $stat     = $params{'stat'}   || '';

    $gen_info || $stat || confess "Required gen_info or stat parameter!";

    return
        $self->plesk->send(
            'customer', 'set',
            {
                filter  => $filter,
                dataset => {
                    gen_info => $gen_info,
                    'stat'   => $stat,
                }
            }
        );
}

=item delete(%params)

Delete accounts.

Params:
limits, permissions, new_data -- hashref`s with corresponding blocks.

And also one of the following options:

  all   => 1      - all accounts.
  login => 'name' - account with a given login.
  id    => 123    - account with a given id 

=cut
sub del {
    my ($self, $filter) = @_;

    return 
        $self->plesk->send(
            'customer',
            'del',
            { filter  => $filter || '' }
        );
}

=item get(%params)

Get account details from Plesk.

Params:

One of the following options:

  all   => 1      - for all accounts.
  login => 'name' - for account with a given login.
  id    => 123    - for account with a given id 

=back

=cut
sub get {
    my ( $self, $filter ) = @_;

    return 
        $self->plesk->send(
            'customer',
            'get', 
            { filter => $filter || ''}
        );
}

1;
