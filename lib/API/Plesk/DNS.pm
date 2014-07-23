
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
        $self->plesk->send('dns', 'add_rec', $data);
}

sub get_rec {
    my ( $self, %filter ) = @_;
    my $bulk_send = delete $filter{bulk_send};
    my $template = delete $filter{template};


    my $data = [
        { filter  => @_ > 2 ? \%filter : '' },
        ( $template ? {template => $template} : () ),
    ];

    return $bulk_send ? $data :
        $self->plesk->send('dns', 'get_rec', $data);
}

sub del_rec {
    my ( $self, %filter ) = @_;
    my $bulk_send = delete $filter{bulk_send};
    my $template = delete $filter{template};

    my $data = [
        { filter  => $self->prepare_filter(\%filter) },
        ( $template ? {template => $template} : () ),
    ];

    return $bulk_send ? $data :
        $self->plesk->send('dns', 'del_rec', $data);
}

sub get_soa {
    my ( $self, %filter ) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = {
        ( %filter ? ( filter => \%filter ) : () ),
        soa     => '',
    };

    return $bulk_send ? $data :
        $self->plesk->send('dns', 'get', $data);
}

sub upd_soa {
    my ( $self, %filter ) = @_;
    my $bulk_send   = delete $filter{bulk_send};

    my %soa_fields = (
        ttl     => delete $filter{ttl},
        minimum => delete $filter{minimum},
        refresh => delete $filter{refresh},
        retry   => delete $filter{retry},
        expire  => delete $filter{expire},
    );

    my %soa = map { $_ => $soa_fields{$_} }
                grep { defined $soa_fields{$_} } keys %soa_fields;

    my $data = {
        ( %filter ? ( filter => \%filter ) : () ),
        soa     => \%soa,
    };

    return $bulk_send ? $data :
        $self->plesk->send('dns', 'set', $data);
}

1;

__END__

=head1 NAME

API::Plesk::DNS - Managing DNS records.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->dns->get_rec(..);
    $response = $api->dns->add_rec(..);
    $response = $api->dns->del_rec(..);
    $response = $api->dns->get_soa(..);
    $response = $api->dns->upd_soa(..);

=head1 DESCRIPTION

Module manage DNS records of the site, site alias or zone template.

=head1 METHODS

=over 3

=item get_rec(%params)

Retrieves the DNS resource records.

    $api->dns->get_rec('site-id' => 1234);

=item add_rec(%params)

Adds resource record(s).

    $api->dns->add_rec(
        'site-id'   => 1234,
        'type'      => 'A',
        'host'      => 'mail',
        'value'     => '192.0.2.12',
    );

=item del_rec(%params)

Removes resource record(s).

    $api->dns->del_rec(id => 67023);

=item get_soa(%params)

Retrives SOA resource record(s).

    $api->dns->get_soa('site-id' => 1234);  # scope: site
    $api->dns->get_soa();                   # scope: zone-template

=item upd_soa(%params)

Updates SOA resource record(s).

    $api->dns->upd_soa(
        'site-id'   => 1234,        # scope: site
        'ttl'       => 86400,       # optional
        'minimum'   => 10800,       # optional
        'refresh'   => 10800,       # optional
        'retry'     => 3600,        # optional
        'expire'    => 604800,      # optional
    );

All missed (optional) parameters of the SOA record will be set by Plesk with defaults as seen above.

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
