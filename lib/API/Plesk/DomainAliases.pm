#
# DESCRIPTION:
#   Plesk communicate interface. Static methods for managing domain aliases.
# AUTHORS:
#   Nikolay Shulyakovskiy (nikolas) <shulyakovskiy@rambler.ru>
#
#========================================================================

package API::Plesk::DomainAliases;

use strict;
use warnings;

use API::Plesk::Methods;
use Data::Dumper;

our $VERSION = '1.03';

=head1 NAME

API::Plesk::DomainAliaeses - extension module to support operations with domainaliases.

=head1 SYNOPSIS

 Directly not used, calls via API::Plesk.

 use API::Plesk;

 my $plesk_client = API::Plesk->new(%params);
 # See documentations for API::Plesk

 $plesk_client->DomainAliases->get(
    domain_name  => 'yandex.ru',
 );

=cut


# Create element
# STATIC (%hash)
# dname => 'domain_name'
# domain_id => 'domain_id_in_plesk'
# If error 2306 -- check template params in panel!
sub create {
    my %params = @_;

    return '' unless $params{'dname'}        &&
                     $params{'domain_id'};
	
    my $pref = '';

    if( $params{pref} ) {
        if ( $params{pref}->{web} ) {
	    $pref .= create_node( 'web', $params{pref}->{web} );
	}

	if ( $params{pref}->{mail} ) {
	    $pref .= create_node( 'mail', $params{pref}->{mail} );
	}
	
        if( $params{pref}->{tomcat} ){
	    $pref .= create_node( 'tomcat', $params{pref}->{tomcat} );
	}

	$pref = create_node( 'pref', $pref );
    }

    return construct_request_xml(
        'domain_alias',
        'create',
	( $pref ? $pref : '' ) . # имхо тут првоерка излишня
        create_node( 'domain_id',  $params{domain_id} ) .
        create_node( 'name',       $params{dname})
    );
}

# Parse XML response
# STATIC (xml_response)
sub create_response_parse {
    my $xml_response = shift;

    my $parse_result =
        $xml_response ? abstract_parser('create', $xml_response, [ ]) : '';
    return '' unless $parse_result;

    return $parse_result;
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


# Delete element
# STATIC( %args )
sub delete {
    my %params = (@_);

    my $filter = '';

    if ( $params{'all'} ) {

        $filter =  create_filter(
            login_field_name => 'login',
            all              => 1,
        ); # warning: get all !!

    } elsif( $params{id} ) {

        $filter = create_filter( id =>  $params{id} );

    } elsif( $params{name} ) {

        $filter =  create_filter(
            login_field_name => 'name',
            name             =>  $params{name},
        );
    } elsif( $params{domain_id} ) {

        $filter =  create_filter(
            login_field_name => 'domain_id',
            domain_id        =>  $params{domain_id},
        );

    } elsif( $params{domain_name} ) {

        $filter =  create_filter(
            login_field_name => 'domain_name',
            domain_name     =>  $params{domain_name},
        );

    } else {

        return '';

    }


    return construct_request_xml( 'domain_alias', 'delete', $filter );
}


# DEL response handler
# STATIC
sub delete_response_parse {
    my $xml_response = shift;

    my $parse_result = $xml_response ?
        abstract_parser('delete', $xml_response, [ ]) : '';
    return '' unless $parse_result;

    return $parse_result;
}


=head1 DESCRIPTION

The method used to get domain aliasses for domain.

=head1 METHODS

=over 3

=item get(%params)

Params:

  id - alias id in Plesk.
  name - alias name in Plesk.
  domain_id - domain id in Plesk.
  domain_name - domain name.

Return:
  
  response object with created domainaliases id in data filed.

=back

=head1 EXPORT

None.

=cut

# Get all element data
# STATIC
sub get {
    my %params = (@_);

    my $filter = '';

    if ($params{'all'} ) {

        $filter =  create_filter(
            login_field_name => 'login',
            all              => 1,
        ); # warning: get all !!

    } elsif( $params{id} ) {

        $filter =  create_filter( id => $params{id} );

    } elsif( $params{name} ) {

        $filter =  create_filter(
            login_field_name => 'name',
            name             =>  $params{name},
        );

    } elsif( $params{domain_id} ) {

        $filter =  create_filter(
            login_field_name => 'domain_id',
            domain_id        => $params{domain_id} 
        );

    } elsif( $params{domain_name} ) {

        $filter =  create_filter(
            login_field_name => 'domain_name',
            domain_name      =>  $params{domain_name} 
        );

    } else {

        return '';

    }


    return construct_request_xml( 'domain_alias', 'get', $filter );
}

# GET response handler 
# STATIC
sub get_response_parse {
    my $xml_response = shift;

    my $parse_result = $xml_response ? abstract_parser('get', $xml_response, [ ]) : '';
    return '' unless $parse_result;
        
    if ( ref $parse_result eq 'HASH' ) {

        if ( $parse_result->{'info'} ) {
	    $parse_result->{'info'} =
                xml_extract_values( transform_block($parse_result->{'info'}, 'info') );

	    if ( $parse_result->{'info'}->{'pref'} ){
                $parse_result->{'info'}->{'pref'} =
                    xml_extract_values( transform_block($parse_result->{'info'}->{'pref'}, 'pref') );
	    }
        } 

    } elsif ( ref $parse_result eq 'ARRAY' ) { # multiple blocks

        foreach my $element (@$parse_result) {

            if ( $element->{'info'} ) {
                $element->{'info'} = xml_extract_values( ( $element->{'info'} )[0] );
                return '' unless $element->{'info'};

		if ( $element->{'info'}->{'pref'} ){
		    $element->{'info'}->{'pref'} =
                        xml_extract_values( transform_block($element->{'info'}->{'pref'}, 'pref') );
	    	}
            } 
        }

    } else {

        return '';

    }

    return $parse_result;
}

sub transform_block {
    my ($block, $sub_block_name) = @_; 

    for ($block) {
        s#<name>(.*?)</name><value>(.*?)</value>#<$1>$2</$1>#sgi;
        s#</?$sub_block_name>##sgi;
    }

    return $block;
}

1;
__END__
=head1 SEE ALSO

Blank.

=head1 AUTHOR

Nikolay Shulyakovskiy E<lt>shulyakovskiy[at]rambler.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Nikolas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
