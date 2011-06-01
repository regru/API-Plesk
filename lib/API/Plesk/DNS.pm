
package API::Plesk::DNS;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

sub add_rec {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};

    my @fields = (
        [qw(site-id site-alias-id)],
        'type',
        'host',
        'value'
    );

    $self->check_required_params(\%params, @fields);
    my $data = $self->sort_params(\%params, @fields, 'opt');

    return $bulk_send ? $data : 
        $self->plesk->send('site', 'get', $data);
}

1;
