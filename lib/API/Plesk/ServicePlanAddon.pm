
package API::Plesk::ServicePlanAddon;

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
        $self->plesk->send('service-plan-addon', 'get', $data);
}

1;
