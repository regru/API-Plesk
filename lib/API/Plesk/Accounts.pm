#
# DESCRIPTION:
#   Plesk communicate interface. Static methods for managing user accounts.
# AUTHORS:
#   Pavel Odintsov (nrg) <pavel.odintsov@gmail.com>
#   Nikolay Shulyakovskiy (nikolas) <shulyakovskiy@rambler.ru>
#
#========================================================================

package API::Plesk::Accounts;

use strict;
use warnings;

use API::Plesk::Methods;
use Data::Dumper;

our $VERSION = '1.03';

=head1 NAME

API::Plesk::Accounts - extension module for the management of user accounts.

=head1 SYNOPSIS

Directly not used, calls via API::Plesk.

 use API::Plesk;

 my $plesk_client = API::Plesk->new(%params);
 # See documentations for API::Plesk

 my $res1 = $plesk_client->Accounts->get(
    id => 36341
 );


=head1 DESCRIPTION

The module provides full support operations with accounts.

=head1 EXPORT

None by default.

=cut

# Elements of %template_data: 
# required - 1 / optional - 0
# min length, max length,
# accepted values

my %template_data = (
    cname   => [0, 0, 60 ], # company name 
    pname   => [1, 1, 60 ],
    login   => [1, 1, 60 ],
    passwd  => [1, 5, 14 ],
    status  => [0, 0, 3, [0, 16]],   
    # status: 
    # 0 - active, 
    # 4 - under backup / restore, 
    # 16 - disabled,
    # 256 Expired, 
    # 64 - disabled by admin.
    phone   => [0, 0, 30  ],
    fax     => [0, 0, 30  ],
    email   => [0, 0, 255 ],
    address => [0, 0, 255 ],
    city    => [0, 0, 50  ],
    state   => [0, 0, 50  ], # For US only
    pcode   => [0, 0, 10  ], # zip code, US only
    country => [0, 2, 2   ], # RU
    locale  => [0, 0, 255 ],
);

=head1 METHODS

=over 3

=item create(%params)

Creates a user account on the basis of the template.

Params:
general_info -- hashref with user data
template-name or template-id

Return: response object with created account id in data filed.

=cut

# Create element
# STATIC (%hash)
# 1) general_info -- hashref with user data (it format in source)
# 2) template-name or template-id -- template identificators
sub create {
    my %params = @_;

    if (ref ($_ = $params{'general_info'}) eq 'HASH') {
        if (client_add_gen_info_check(%{ $params{'general_info'} })) {

            my $template = '';
        
            if ($params{'template-name'}) {
                
                $template = create_node('template-name', 
                    $params{'template-name'});

            } elsif ($params{'template-id'}) {
                
                $template = create_node('template-id', 
                    $params{'template-id'});
            
            } else {
                return ''; # template required
            }
            return construct_request_xml( 'client', 'add', 
                generate_info_block('gen_info', select_only_allowed_fields($params{'general_info'}) ), 
                    $template);
        } else {
            return ''; # not enought data
        }
    } else {
        return '';  # not enought data
    }
}

# Return only allowed fields
# STATIC
sub select_only_allowed_fields {
    my $hashref = shift;

    return map {
        $hashref->{$_} ? ($_, $hashref->{$_}) : ( );
    } sort keys %template_data
}

# Parse XML response
# STATIC (xml_response)
# return hashref if one result block
# return arref of hashref if multiple errors 
sub create_response_parse {
    my $xml_from_server = shift; 

    return '' unless $xml_from_server;

    return abstract_parser('add', $xml_from_server, ['status']);
}

=item modify(%params)

Changes the parameters account.

Params:
limits, permissions, new_data -- hashref`s with corresponding blocks.

And also one of the following options:

  all   => 1      - for all accounts.
  login => 'name' - for a given login.
  id    => 123    - for a given id 

=cut

# Modify element
# STATIC
sub modify {
    my %params = @_;

    my $filter;

    $params{'limits'} ||= '';
    $params{'permissions'} ||= '';
    $params{'new_data'} ||= '';

    my $limits_block = ref $params{'limits'} eq 'HASH' &&  %{$params{'limits'}}?
        generate_settings_block('limit' ,%{ $params{'limits'} }) : '';  
 
    my $permissions_block = ref $params{'permissions'} eq 'HASH' && %{$params{'limits'}} ?
        generate_settings_block( 'permission', %{ $params{'permissions'} }) : '';   

    my $gen_info_block = ref $params{'new_data'} eq 'HASH' && %{$params{'new_data'}} ?
        generate_info_block('gen_info', %{ $params{'new_data'} }) : '';

    if ($params{'all'}) {
        $filter =  create_filter(login_field_name => 'login', all => 1);  # warning: modify all !!
    } elsif ($params{'id'} || $params{'login'}) {
        $filter = create_filter(login_field_name => 'login', %params);
    } else {
        $filter = '';
    }

    if ($filter && ($limits_block || $permissions_block || $gen_info_block)) {

        return construct_request_xml( 'client', 'set', $filter, 
            create_node(
                'values', $gen_info_block . $limits_block . $permissions_block
            )
        );
    } else {

        return '';

    }
}


# SET response handler
# STATIC
sub modify_response_parse {
    my $xml_from_server = shift; 

    return '' unless $xml_from_server;

    return abstract_parser('set', $xml_from_server, ['status']);
}

=item delete(%params)

Delete accounts.

Params:
limits, permissions, new_data -- hashref`s with corresponding blocks.

And also one of the following options:

  all   => 1      - all accounts.
  login => 'name' - account with a given login.
  id    => 123    - account with a given id 

=cut

# Delete element
# STATIC( %args )
# login => 'userlogin' or id => 12312 or all => 1
sub delete {
    my %params = @_;

    my $filter = '';

    if ($params{'all'}) {
        $filter =  create_filter(login_field_name => 'login', all => 1); # warning: delete all !!
    } elsif ($params{'id'} || $params{'login'}) {
        $filter =  $params{'id'} ?
            create_filter( login_field_name => 'login', id    => $params{'id'}) :
            create_filter( login_field_name => 'login', login => $params{'login'});
    } else {
        $filter = '';
    }
  
    return $filter ? construct_request_xml('client', 'del', $filter) : '';
}


# DEL response handler
# STATIC
sub delete_response_parse {
    my $xml_from_server = shift;

    return '' unless $xml_from_server;

    return abstract_parser('del', $xml_from_server, ['status']);
}


=item get(%params)

Get account details from Plesk.

Params:

One of the following options:

  all   => 1      - for all accounts.
  login => 'name' - for account with a given login.
  id    => 123    - for account with a given id 

=back

=cut


# Get all element data
# STATIC( %args )
# login => 'userlogin', id => 12312, all => 1
sub get {
    my %params = (permissions => 0, limits => 0, stat => 0, @_);

    my $filter = '';

    if ($params{'all'}) {
        $filter =  create_filter(login_field_name => 'login', all => 1); # warning: get all !!
    } elsif ($params{'id'} || $params{'login'}) {
        $filter = $params{'id'} ?
            create_filter( login_field_name => 'login', id    => $params{'id'}) :
            create_filter( login_field_name => 'login', login => $params{'login'});
    } else {
        $filter = '';
    } 

    my $addition_blocks = 
       ( $params{stat}        ? create_node('stat')        : '' ) .
       ( $params{permissions} ? create_node('permissions') : '' ) .
       ( $params{limits}      ? create_node('limits')      : '' ) .
       ( $params{ippool}      ? create_node('ippool')      : '' );

    # don`t use limits, preferences sequence!!!!
    # only preferences, limits! Probably Plesk bug.
    return construct_request_xml('client', 'get', $filter, 
        create_node ('dataset', create_node('gen_info') . $addition_blocks)
    );
}


# GET response handler 
# STATIC
sub get_response_parse {
    my $xml_from_server = shift;

    return '' unless $xml_from_server;
    
    my $parse_result = abstract_parser('get', $xml_from_server, ['status']);
    return '' unless $parse_result;
        
    if (ref $parse_result eq 'HASH') {
        if ($parse_result->{'data'}) {
            
            my $limits = ($parse_result->{'data'} =~ m#<limits>(.*?)</limits>#sio)[0];
            
            if ($limits) {
                $limits = xml_extract_values( transform_block($limits, 'limit') );
                $parse_result->{'limits'} = $limits;
            }


            my $stat = ($parse_result->{'data'} =~ m#<stat>(.*?)</stat>#sio)[0];
           
            if ($stat) {
                $stat = xml_extract_values( transform_block($stat, 'stat') );
                $parse_result->{'stat'} = $stat;
            }
 
            my $ippool = ($parse_result->{'data'} =~ m#<ippool>(.*?)</ippool>#sio)[0];
             
            if ($ippool) {
               $ippool = xml_extract_values( transform_block($ippool, 'ippool') );
               $parse_result->{'ippool'} = $ippool;
            }

            my $permissions = ($parse_result->{'data'} =~ m#<permissions>(.*?)</permissions>#sio)[0];

            if ($permissions){
                $permissions = xml_extract_values( transform_block($permissions, 'permission') );
                $parse_result->{'permissions'} = $permissions;
            }

            $parse_result->{'data'} = xml_extract_values(
                    ( $parse_result->{'data'} 
                        =~ m#<gen_info>(.*?)</gen_info>#sio)[0]);

            return '' unless $parse_result->{'data'};
        } 
    } elsif (ref $parse_result eq 'ARRAY'){ # multiple blocks
        foreach my $element (@$parse_result) {
            my $limits = ($element->{'data'} =~ m#<limits>(.*?)</limits>#sio)[0];
             
            if ($limits) {
                $limits = xml_extract_values( transform_block($limits, 'limit') );
                $element->{'limits'} = $limits;
            }
 
            my $stat = ($element->{'data'} =~ m#<stat>(.*?)</stat>#sio)[0];
            
            if ($stat) {
                $stat = xml_extract_values( transform_block($stat, 'stat') );
                $element->{'stat'} = $stat;
            }

            my $ippool = ($element->{'data'} =~ m#<ippool>(.*?)</ippool>#sio)[0];
            
            if ($ippool) {
                $ippool = xml_extract_values( transform_block($ippool, 'ippool') );
                $element->{'ippool'} = $ippool;
            }

            my $permissions = ($element->{'data'} =~ m#<permissions>(.*?)</permissions>#sio)[0];

            if ($permissions){
                $permissions = xml_extract_values( transform_block($permissions, 'permission') );
                $element->{'permissions'} = $permissions;
            }


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

# Input data control for create sub
# STATIC
sub client_add_gen_info_check {
    my %params = @_;

    foreach my $key (keys %template_data) { 

        if ($_ = $params{$key}) {
            return '' unless ( 
                                length $_ >= $template_data{$key}->[1]  && 
                                length $_ <= $template_data{$key}->[2] 
            );
        } else {                                    # value not defined
            return '' if $template_data{$key}->[0]; # if required => error 
        }

    }   
    return 1; # all ok
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
