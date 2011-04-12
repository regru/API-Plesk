
package API::Plesk::ServicePlan;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

sub get {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = { 
        filter => @_ > 2 ? \%filter : '',
    };

    return $bulk_send ? $data : 
        $self->plesk->send('service-plan', 'get', $data);
}

1;

__END__

=head1 NAME

API::Plesk::ServicePlan -  Managing service plans.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->service_plan->get(..);

=head1 DESCRIPTION

Module manage service plans.

=head1 METHODS

=over 3

=item get(%params)

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut

