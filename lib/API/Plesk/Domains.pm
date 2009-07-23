#
# DESCRIPTION:
#   Plesk communicate interface. Static methods for managing domain accounts.
# AUTHORS:
#   Pavel Odintsov (nrg) <pavel.odintsov@gmail.com>
#   Nikolay Shulyakovskiy (nikolas) <shulyakovskiy@rambler.ru>
#
#========================================================================

package API::Plesk::Domains;

use strict;
use warnings;

use API::Plesk::Methods;
use Data::Dumper;

our $VERSION = '1.03';

=head1 NAME

API::Plesk::Domains - extension module to support operations with domains (only create).

=head1 SYNOPSIS

 Directly not used, calls via API::Plesk.

 use API::Plesk;

 my $plesk_client = API::Plesk->new(%params);
 # See documentations for API::Plesk

 $plesk_client->Domains->create(
    dname        => 'yandex.ru',
    ip           => '192.168.1.99',
    client_id    =>  12345,
    ftp_login    => 'asdasdad',
    ftp_password => 'qwertsdasy',
    template     => 'tariff1',
 );

=head1 DESCRIPTION

The method used to add domain hosting account to a certain Plesk account.

=head1 METHODS

=over 3

=item create(%params)

Params:

  dname - domain name,
  ip  - ip address for hosting (shared),
  client_id - client id in Plesk.
  ftp_login  - ftp login for hosting,
  ftp_password - ftp pass for hosting,
  template - domain template name in Plesk.

Return:
  
  response object with created domain id in data filed.

=back

=head1 EXPORT

None.

=cut

# Create element
# STATIC (%hash)
# dname => 'domain_name'
# ip => 'ip_address'
# client_id => 'client_id_in_plesk'
# ftp_login -- login for ftp
# ftp_password -- password for ftp
# template -- domain template in Plesk
# If error 2306 -- check template params in panel!
sub create {
    my %params = @_;

    return '' unless $params{'dname'}        &&
                     $params{'ip'}           &&
                     $params{'client_id'}    &&
                     $params{'ftp_login'}    &&
                     $params{'ftp_password'} &&
                     $params{'template'};

    my $hosting_block = create_node('hosting',
        generate_info_block(
            'vrt_hst',
            'ftp_login'    => $params{'ftp_login'},
            'ftp_password' => $params{'ftp_password'},
            'ip_address'   => $params{'ip'}
        )
    );
    my $template_block =  create_node('template-name', $params{'template'});

    return construct_request_xml( 'domain', 'add',
        generate_info_block(
            'gen_setup',
            name        => $params{dname},
            client_id   => $params{client_id},
            htype       => 'vrt_hst',
            ip_address  => $params{ip}, 
            status      => 0,
        ) . $hosting_block . $template_block        
    )
}


# Parse XML response
# STATIC (xml_response)
sub create_response_parse {
    my $xml_response = shift;

    return '' unless $xml_response;

    return abstract_parser("add", $xml_response, [ ]);
}




# SET response handler
# STATIC
sub modify_response_parse {
    # stub
}


# Delete element
# STATIC( %args )
sub delete {
    # stub
}


# DEL response handler
# STATIC
sub delete_response_parse {
    # stub
}


# Get all element data
# STATIC
sub get {
    my %params = @_;

    my $filter;

    if ($params{client_id}) {
        $filter =  create_filter(
            login_field_name => 'client_id',
            client_id        =>  $params{client_id} 
        );
    } elsif ($params{client_login}) {

        $filter =  create_filter(
            login_field_name => 'client_login',
            client_login     =>  $params{client_login} 
        );

    } elsif ($params{domain_name}) {

        $filter =  create_filter(
            login_field_name => 'domain_name',
            domain_name      =>  $params{domain_name},
        );

    } elsif ( $params{all} ) {
        $filter = create_node( 'filter' );
    } else {
        return '';
    }

    my $addition_blocks = ($params{stat} ? create_node('stat') : '') .
       ($params{limits} ? create_node('limits') : '');
  
    return construct_request_xml( 'domain', 'get', $filter . create_node('dataset', $addition_blocks));
 
    # hm....TODO 
    # don`t use limits, preferences sequence!!!!
    # only preferences, limits! Probably Plesk bug.
    return construct_request_xml('client', 'get', $filter, 
        create_node ('dataset', create_node('gen_info') . $addition_blocks)
    );
}


# GET response handler 
# STATIC
sub get_response_parse {
    my $xml_response = shift;
  
    my $parse_result = $xml_response ? abstract_parser('get', $xml_response, [ ]) : '';
    return '' unless $parse_result;
        
    if (ref $parse_result eq 'HASH') {
        if ($parse_result->{'data'}) {
            
            my $limits = ($parse_result->{'data'} =~ m#<limits>(.*?)</limits>#sio)[0];
            
            if ($limits) {
                $limits = xml_extract_values( transform_block($limits, 'limit') );
                $parse_result->{'limits'} = $limits;
            }

            my $stat = ($parse_result->{'data'} =~ m#<stat>(.*?)</stat>#sio)[0];

            if ($stat){
                $stat = xml_extract_values( transform_block($stat, 'stat') );
                $parse_result->{'stat'} = $stat;
            }

            $parse_result->{'data'} = xml_extract_values(
                    ( $parse_result->{'data'} 
                        =~ m#<gen_info>(.*?)</gen_info>#sio)[0]);

            return '' unless $parse_result->{'data'};
        } 
    } elsif (ref $parse_result eq 'ARRAY'){ # multiple blocks
        foreach my $element (@$parse_result) {

            if ($element->{'data'}) {
                $element->{'data'} = xml_extract_values(( $element->{'data'} 
                    =~ m#<gen_info>(.*?)</gen_info>#sio )[0]);

                return '' unless $element->{'data'};
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

Odintsov Pavel E<lt>nrg[at]cpan.orgE<gt>
Nikolay Shulyakovskiy E<lt>shulyakovskiy[at]rambler.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by NRG

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
