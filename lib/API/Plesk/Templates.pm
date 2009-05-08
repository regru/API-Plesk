#
# DESCRIPTION:
#   Plesk communicate interface. Static methods for managing templates (accounts, domain)
#   reduced functional, only get template preferences.
# AUTHORS:
#   Pavel Odintsov (nrg) <pavel.odintsov@gmail.com>
#
#========================================================================

package API::Plesk::Templates;

use strict;
use warnings;

use API::Plesk::Methods;
use Data::Dumper;

our $VERSION = '1.03';

=head1 NAME

API::Plesk::Templates - extension module for obtaining information about the limitations of the template account.

=head1 SYNOPSIS

Directly not used, calls via API::Plesk.

 use API::Plesk;

 my $plesk_client = API::Plesk->new(%params);
 # See documentations for API::Plesk

 my $res1 = $plesk_client->Templates->get(
    name => 'tariff1',
    type => 'account'
 );


=head1 DESCRIPTION

The module provides information extraction of the restrictions and permits from user account Templates.
Creating templates via API possible, but not implemented.

=cut

=head1 METHODS

=over 3

=item get(%params)

Params:

  name or id -- name or identifier desired template
  type can be 'domain' or 'account', has been implemented only account.

Template->get returned API::Plesk::Response object.
Always returned arrref from response blocks (hash refs), if the request was alone, we need only the first element, ie $res->get_data->[0].

There are three result hash refs in this hash: limits, permissions and ip-pool. Ex:
  $res->get_data->[0]->{limits};

For more details, see the documentation for the Plesk.

=back

=cut

# Get all element data
# STATIC( %args )
# name => 'template_name' or id => 'template_id' 
# type => 'domain' or type => 'account'
sub get {
    my %params = @_;

    if ( $params{type} eq 'account') {
        my $filter;

        if ($params{'name'}) {
            $filter =  create_filter( login_field_name => 'name', name => $params{name});
        } elsif ($params{'id'}) {
            $filter = create_filter( login_field_name => 'name', id => $params{id});
        } else {
            # not enought data
        }   
    
        return $filter ? construct_request_xml( 'client-template', 'get', $filter,
            '<limits/><permissions/><ip-pool/><preferences/>',) : '';

    } elsif ($params{type} eq 'domain') {
        # TODO
    } else {
        return ''; # error
    }
}


# GET response handler 
# STATIC
# Return hashref of hashrefs
sub get_response_parse {
    my ($xml_from_server, %params) = @_;

    my $parser_result = abstract_parser('get', $xml_from_server, []);
    return '' unless $parser_result;

    return '' unless $params{type};    

    if ($params{type} eq 'account') {
        foreach my $block  ('ip-pool', 'permissions', 'limits') {
            return '' unless $parser_result->{$block};
        
            if ($block eq 'ip-pool') {
                # NOP
            } else {
                my $sub_block_name = ($block =~ m/^(.*?)s$/si)[0];

                for ($parser_result->{$block}) {
                    s#<name>(.*?)</name><value>(.*?)</value>#<$1>$2</$1>#sgi;
                    s#</?$sub_block_name>##sgi;
                }
                $parser_result->{$block} = xml_extract_values($parser_result->{$block});

                return '' unless $parser_result->{$block}; # check blocks after parsing
            }
        }
    } elsif ($params{type} eq 'domain') {
        # code
    } else {
        return ''; # error in type
    }

    return $parser_result;
}


1;
__END__
=head2 EXPORT

None.

=head1 SEE ALSO

Blank.

=head1 AUTHOR

Odintsov Pavel E<lt>nrg[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by NRG

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
