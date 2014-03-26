
package API::Plesk::Reseller;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

my @gen_info_fields = qw(
    cname
    pname
    login
    passwd
    status
    phone
    fax
    email
    address
    city
    state
    pcode
    country
    locale
    external-id
);

sub add {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};
    my $gen_info  = $params{gen_info} || confess "Required gen_info parameter!";

    $self->check_required_params($gen_info, qw(pname login passwd));

    my $data = {
        gen_info => $self->sort_params($params{gen_info}, @gen_info_fields)
    };

    return $bulk_send ? $data :
        $self->plesk->send('reseller', 'add', $data);
}

sub get {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = {
        filter => @_ > 2 ? \%filter : '',
        dataset => [
            {'gen-info'     => ''},
            {stat           => ''},
            {permitions     => ''},
            {limits         => ''},
            {ippool         => ''},
            {subsccriptions => ''},
        ]
    };

    return $bulk_send ? $data :
        $self->plesk->send('reseller', 'get', $data);
}

sub set {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};
    my $filter    = $params{filter}   || '';
    my $gen_info  = $params{gen_info} || '';

    $gen_info || confess "Required gen_info or stat parameter!";

    my $data = {
        filter  => $filter,
        values => {
            'gen-info' => $gen_info,
        }
    };

    return $bulk_send ? $data :
        $self->plesk->send('reseller', 'set', $data);
}

sub del {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data :
        $self->plesk->send('reseller', 'del', $data);
}

1;

__END__

=head1 NAME

API::Plesk::Reseller -  Managing reseller accounts.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->reseller->add(..);
    $response = $api->reseller->get(..);
    $response = $api->reseller->set(..);
    $response = $api->reseller->del(..);

=head1 DESCRIPTION

Module manage reseller accounts.

=head1 METHODS

=over 3

=item add(%params)

Method adds reseller to Plesk Panel.

    %params = (
        # required
        gen_info => {
            pname => 'Mike',
            login => 'mike',
            passwd => '12345',
            ...
        }
    );

=item get(%params)

Method gets reseller data.

    %params = (
        filter => {...}
    );

=item set(%params)

Method sets reseller data.

    %params = (
        filter   => {...},
        gen_info => {...}
    );

=item del(%params)

Method deletes reseller from Plesk Panel.

    %params = (
        filter => {...}
    );

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
