#
# DESCRIPTION:
#   Plesk communicate interface. Static methods for managing database users.
# AUTHORS:
#   Pavel Odintsov (nrg) <pavel.odintsov@gmail.com>
#
#========================================================================

package API::Plesk::DatabaseUsers;

use strict;
use warnings;

use API::Plesk::Methods;
use Data::Dumper;

our $VERSION = '1.03';

=head1 NAME

API::Plesk::Databases - extension module for managing databases.

=head1 SYNOPSIS

 Directly not used, calls via API::Plesk.

 use API::Plesk;
 use API::Plesk::Response;

 my $plesk_client = API::Plesk->new(%params);
 # See documentations for API::Plesk

 $plesk_client->Databases->create(
    'name'         => 'good_base',
    'domain-id'    =>  12345,
    'type'         => 'mysql',
    'db-server-id' => 1,
 );

=over 3

=item create(%params)

The method used to add database to a certain Plesk domain account.

Params:

 name - db name (lower case preferably),
 domain-id - domain id in Plesk,
 type - type of bd: mysql, mssql (Windows only) or postrgesql,
 db-server-id - db server identification number (1 -- default),

Return:

 response object with created database id in data filed.

=cut

# Create element
# STATIC (%params)
sub create {
    my %params = @_;

    return '' unless $params{'login'}     &&
                     $params{'db-id'}     &&
                     $params{'password'};

    my $db_params = '';
    foreach my $key ('db-id', 'login', 'password') {   
        $db_params .= create_node( $key, $params{$key});
    }

    return construct_request_xml( 'database', 'add-db-user', $db_params );
}


# Parse XML response
# STATIC (xml_response)
sub create_response_parse {
    my $xml_response = shift;

    return $xml_response ? abstract_parser('add-db-user', $xml_response, [ ]) : '';
}


=item delete(%params)

Delete database account for certain Plesk Domain (selected by id or name).

Params:

 'db-id' - database id or 
 'domain-id' - delete all bases for domain with certain id in Plesk or 
 'domain-name' - delete all bases for domain with certain domain name in Plesk,

Return:

 API::Plesk::Response object

=back

=cut

# Delete element
# STATIC( %args )
sub delete {
    my %params = @_;

    my $db_filter = '';

    if ($params{'id'}) {
        $db_filter = create_filter(
            login_field_name => 'id',
            'id'             => $params{'id'}
       ); 
    } elsif ( $params{'db-id'} ) {
        $db_filter = create_filter(
            login_field_name => 'db-id',
            'db-id'          => $params{'db-id'}
        );
    } else {
        return ''; # errror
    }

    return construct_request_xml( 'database', 'del-db-user', $db_filter );
}


# DEL response handler
# STATIC
sub delete_response_parse {
    my $xml_response = shift;

    return $xml_response ? abstract_parser('del-db-user', $xml_response, [ ]) : '';
    # stub
}


# Get all element data
# STATIC
sub get {
    my %params = @_;

    return "<database><get-db-users><filter><db-id>$params{database_id}</db-id>" . 
        "</filter></get-db-users></database>";
}


# GET response handler
# STATIC
sub get_response_parse {
    my $xml_response = shift;

    my $result = $xml_response ? abstract_parser('get-db-users', $xml_response, [ ]) : '';
    ## warn Dumper($result);
    return $result;
}


# Modify element
# STATIC
sub modify {
    # stub
}


# SET response handler
# STATIC
sub modify_response_parse {
    # stub
}

=head1 EXPORT

None.

=cut

1;

__END__
=head1 SEE ALSO

Blank.

=head1 AUTHOR

Odintsov Pavel E<lt>nrg[at]cpan.orgE<gt>
Nikolay Shulyakovskiy E<lt>shulyakovskiy[at]rambler.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by NRG

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
