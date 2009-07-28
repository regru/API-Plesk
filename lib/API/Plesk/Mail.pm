#
# DESCRIPTION:
#   Plesk communicate interface. Static methods for managing user mail.
# AUTHORS:
#   Pavel Odintsov (nrg) <pavel.odintsov@gmail.com>
#
 #========================================================================


package API::Plesk::Mail;
 
use strict;
use warnings;
 
use API::Plesk::Methods;
use Data::Dumper;
 
our $VERSION = '1.03';

sub get {
    my %params = @_;

    return "<mail><get_info><filter><domain_id>$params{domain_id}</domain_id></filter>" .
        "<cp_access/><mailbox/></get_info></mail>";
}

sub get_response_parse {
    my $xml_response = shift;

    my $parse_result = $xml_response ? abstract_parser('mail', $xml_response, [ ]) : '';
    return '' unless $parse_result;

    if ($parse_result && ref $parse_result eq 'ARRAY') {
        for (@$parse_result) {
            $_->{mailname} = xml_extract_values($_->{mailname});
    
            for my $type ('mailbox', 'cp_access') {
                $_->{mailname}->{$type} = xml_extract_values( $_->{mailname}->{$type} );
            }

            $_->{mailname}->{cp_access}->{access} = xml_extract_values( $_->{mailname}->{cp_access}->{access} );
        }   
    } else {
        if ($parse_result->{mailname}) {
            $parse_result->{mailname} = xml_extract_values( $parse_result->{mailname} );
        } else {
            # Dumper($parse_result);
        }
    }

    return $parse_result;
}
