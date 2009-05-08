#
# DESCRIPTION:
#   Plesk communicate interface. Some methods for Plesk methods (Accounts, Domains, Templates).
# AUTHORS:
#   Pavel Odintsov (nrg) <pavel.odintsov@gmail.com>
#
#========================================================================

package API::Plesk::Methods;

use strict;
use warnings;

use Carp;
use Data::Dumper;

our $VERSION = '1.03';

=head1 NAME

API::Plesk::Methods - some service functions for a writing our extensions.

=head1 SYNOPSIS

use API::Plesk::Methods;

=head1 DESCRIPTION

Several support functions to generate xml, xml parsing and data control.

=head1 EXPORT

See METHODS block.

=cut

our @EXPORT = qw(
    generate_info_block
    generate_settings_block
    construct_request_xml
    create_filter
    create_node
    xml_extract_values
    abstract_parser
);


=head1 METHODS

=over 3

=item construct_request_xml($type, $operation, @addition_blocks) 

Construct xml query:
 <$type><$operation>@addition_blocks</$operation></$type>

 $type -- client-template, client
 $operation -- type of operation: ADD, GET, SET, DEL
 @addition_blocks -- other xml blocks

=cut 

# Create xml query
# STATIC (operation*, type*, addition_blocks)
# $type -- client-template, client
# $operation -- type of operation: ADD, GET, SET, DEL
# @addition_blocks -- other xml blocks
sub construct_request_xml {
    my ($type, $operation, @addition_blocks) = @_;

    return '' unless $operation && $type; 
    
    return create_node($type, create_node($operation, (join '', @addition_blocks) || undef ));
}


# Generate settings XML block (limits, permissons, preferences)
# STATIC (block_type, settings_hash)
# $block_type -- type of block without trailing 's', limit (not limits!), permission
# $settings_hash -- key => value pairs of setting
sub generate_settings_block {
    my ($block_type, %settings) = @_;

    return '' unless $block_type;
    return create_node("${block_type}s") if scalar keys %settings < 1;

    my $settings_block = "<${block_type}s>";
    for my $setting_name (sort keys %settings) {
        $settings_block .= create_node($block_type, 
                              create_node('name', $setting_name). 
                                  create_node('value', $settings{$setting_name})) ;   
    }
    return $settings_block ."</${block_type}s>";;
}


# Abstract func for creating user info blocks
# STATIC (user_info_block_type, user_info)
# $user_info_block_type -- block type without trailing 's', gen_info (not gen_infos!)
# %user_info -- key => value pairs of setting
sub generate_info_block {
    my ($user_info_block_type, %user_info) = @_;
        
    return '' unless $user_info_block_type;
    return create_node($user_info_block_type) if scalar keys %user_info < 1;

    my $block = "<${user_info_block_type}>";    
    $block .= create_node($_, $user_info{$_}) for sort keys %user_info;
    $block .= "</${user_info_block_type}>";

    return $block;
}


=item create_filter(%params)

Construct xml filter.

Params:
  login_field_name => 'value' -- filter by "..." value.

  all              => 1      - select all accounts.
  login_field_name => 'name' - select account with a given login_field_name.
  id               => 123    - select account with a given id 

=cut 

# Create filter
# STATIC (ident_hash);
# Params: unique login or unique id or 'all' for request all data
# Set filter by field: login_field_name => 'field_name'
sub create_filter {
    my %params = @_;
 
    my $login_field_name = $params{'login_field_name'}; 

    if ($params{'id'}) {

        return create_node('filter', 
            create_node('id', $params{'id'}));

    } elsif ($params{$login_field_name}) {

        return create_node( 'filter', 
            create_node($login_field_name, $params{$login_field_name}) );

    } elsif ($params{'all'}) {
        return create_node('filter'); # blank filter query -- SELECT * for Plesk
    } else {
        return '';
    }
}


# Only create XML node
# STATIC(node_name, node_value);
sub create_node {
    my ($node_name, $node_value) = @_;

    return defined $node_value ? "<$node_name>$node_value</$node_name>" :
        "<$node_name/>";
}

=item xml_extract_values($data)
	
Extracts from xml pair of key -- data, where the key is the node name and the value of its contents.

If success return hashref.

=cut

# Extracts name -> value pairs from xml
# STATIC
sub xml_extract_values {
    my $xml_data = shift;
    return '' unless $xml_data;

    my $result = { };

    while ( $xml_data =~ m#<(.*?)>(.*?)</\1>#gsi ) {
        unless($result->{$1}) {
            $result->{$1} = $2;
        } else {
            if (ref $result->{$1} eq 'ARRAY') {
                push @{ $result->{$1} }, $2; 
            } else {
                my $first_elem = $result->{$1};
                $result->{$1} = [ $first_elem, $2 ];
            }
        }
    }

    return $result;
}

=item abstract_pasrser($operation_type, $xml_from_server, $required_data)

Provides parsing $xml_from_server previously extracting content block <$operation_type>.
Also performed to check if the keys, a list of which appears in arrref $required_data

=back

=cut 

# Abstract parser sub 
# STATIC
sub abstract_parser {
    my $operation_type  = shift; # del, add, set, get
    my $xml_from_server = shift;
    my $required_data   = shift; # arref
    my $system_error_block_name = shift;

    $system_error_block_name ||= 'system';

    return '' unless $operation_type    && 
                     $xml_from_server   && 
                     ref $required_data eq 'ARRAY';

    my $result;
    my @result_blocks;  
    my $xml_cut = ($xml_from_server 
                    =~ m#<$operation_type>(.*?)</$operation_type>#gis)[0];

    # if not found operation_type block, find system block
    if ($xml_cut) {
        while ($xml_cut =~ m#<result>(.*?)</result>#giso) {
            push @result_blocks, $1 if $1;
        }
    } else {
        $xml_cut = ($xml_from_server 
                    =~ m#<$system_error_block_name>(.*?)</$system_error_block_name>#gis)[0];
        if ($xml_cut) {
            push @result_blocks, $xml_cut;
        } else {
            return ''; # block <op_type> or <system> not found
        }
    }


    if (scalar @result_blocks > 1) {

        for (@result_blocks) {   
            my $key_value_pairs = xml_extract_values($_);
            return $result unless $key_value_pairs && 
                check_required_keys($key_value_pairs, $required_data);

            push @$result, $key_value_pairs; # return arrref of hashref
        } 

    } elsif (scalar @result_blocks == 1) {
        $result = xml_extract_values(shift @result_blocks); # return hashref
        return '' unless check_required_keys($result, $required_data);

    } else {
        # no blocks, error
    }
    return $result;
}


# Check required data fields
# STATIC(input_hash_ref, required_fields)
sub check_required_keys {
    my $processed_hash_ref = shift;
    my $required_keys      = shift; # arr ref
    return '' unless ref $required_keys      eq 'ARRAY' &&   
                     ref $processed_hash_ref eq 'HASH';

    for (@$required_keys) {
        return '' unless $processed_hash_ref->{$_};
    }  

    return 1;
}


# Light weight Exporter
sub import {
    no strict 'refs';
    my $called_from = caller;

    foreach my $package_sub (@EXPORT) {
        # importing our sub into caller`s namespace
        *{$called_from . '::' . $package_sub} = \&$package_sub;
    }
}


1;
__END__
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
