
package API::Plesk::Subdomain;

use strict;
use warnings;

use Carp;
use Data::Dumper;

use base 'API::Plesk::Component';

#TODO

sub get {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = {
        filter  => @_ > 2 ? \%filter : '',
    };

    return $bulk_send ? $data :
        $self->plesk->send('subdomain', 'get', $data);
}

1;

__END__

=head1 NAME

API::Plesk::Subdomain -  Managing subdomains.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->subdomain->get(..);

=head1 DESCRIPTION

Module manage subdomains.

=head1 METHODS

=over 3

=item get(%params)

=back

=head1 AUTHOR

Eugeny Zavarykin <lt>zavarykin@reg.ru<gt>

=cut
