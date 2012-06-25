
package API::Plesk::ServicePlanAddon;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

my @main_fields = qw/
    owner-id
    owner-login
/;

sub get {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = {};
    $data->{filter} = @_ > 2 ? \%filter : '';
    foreach my $field ( @main_fields ) {
	if ( exists $data->{filter}->{ $field } ) {
	    $data->{ $field } = delete $data->{filter}->{ $field };
	}
    }

    return $bulk_send ? $data : 
        $self->plesk->send('service-plan-addon', 'get', $data);
}

1;

__END__

=head1 NAME

API::Plesk::ServicePlanAddon -  Managing add-on plans.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->service_addon_plan->get(..);

=head1 DESCRIPTION

Module manage add-on plans.

=head1 METHODS

=over 3

=item get(%params)

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut

