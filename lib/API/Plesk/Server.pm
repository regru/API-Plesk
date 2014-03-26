
package API::Plesk::Server;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

sub set {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};

    my $data = { %params };

    return $bulk_send ? $data :
        $self->plesk->send('server', 'set', $data);
}

1;

__END__

=head1 NAME

API::Plesk::Server -  Managing Plesk server.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->server->set(..);

=head1 DESCRIPTION

Module manage Plesk server.

=head1 METHODS

=over 3

=item set(%params)

Method sets server parameters.

    %params = (
        ...
    );

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
