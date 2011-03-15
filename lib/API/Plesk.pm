#
# DESCRIPTION:
#   Plesk communicate interface. Main class.
# AUTHORS:
#   Pavel Odintsov (nrg) <pavel.odintsov@gmail.com>
#   Nikolay Shulyakovskiy E<lt>shulyakovskiy[at]rambler.ruE<gt>
#
#========================================================================

package API::Plesk;

use strict;
use warnings;
use lib qw(../..);

use Data::Dumper;
use Carp;

use HTTP::Request;
use LWP::UserAgent;
use XML::Fast;

our $VERSION = '2.00';

has_component('Customers');

=head1 NAME

API::Plesk - OOP interface to the Plesk XML API (http://www.parallels.com/en/products/plesk/).

=head1 SYNOPSIS

    use API::Plesk;
    use API::Plesk::Response;

    my $plesk_client = API::Plesk->new(%params);
    my $res = $plesk_client->Func_Module->operation_type(%params);

    if ($res->is_success) {
        $res->get_data; # return arr ref of answer blocks
    }

=head1 DESCRIPTION

At present the module provides interaction with Plesk 8.3.0 (API 1.5.0.0). Complete support of operations with Accounts, partial support of work with Templates (account and domains). Support of addition of domains to user Accounts.

API::Plesk module gives the convenient interface for addition of new functions. Extensions represent modules in a folder Plesk with definitions of demanded functions. Each demanded operation is described by two functions: op and op_response_parse. The first sub generates XML query to Plesk, the second is responsible for parse XML answer and its representation in Perl Native Structures. As a template for a writing of own expansions is better to use API/Plesk/Account.pm. In module API::Plesk::Methods we can find service functions for a writing our extensions.

For example, here the set of subs in the Accounts module is those.

  create  / create_response_parse
  modify  / modify_response_parse
  delete  / delete_response_parse
  get     / get_response_parse

=head1 EXPORT

Nothing.

=head1 METHODS
=over 3

=item new(%params)

Create new class instance.

Required params:

  api_version -- default: 1.6.3.0
  username -- Plesk user name.
  password -- Plesk password.
  url -- full url to Plesk XML RPC gate (https://ip.ad.dr.ess:8443/enterprise/control/agent.php).

=cut

# Create object
# STATIC
sub new {
    my $class = shift;

    $class = ref ($class) || $class;
    my %params = @_;
    
    my $self = { 
        api_version   => $params {api_version} || '1.6.3.0',
        username      => $params {username},
        password      => $params {password},
        url           => $params {url},
        debug         => $params {debug},
        timeout       => $params {timeout} || 10,
        request_debug => 0,           # only for debug XML requests
    };
    
    return bless $self, $class;
}

=item AUTOLOADed methods

All other methods are loaded by Autoload from corresponding modules. 
Execute some operations (see API::Plesk::* modules documentation).

Example:
 
  my $res = $plesk_client->Func_Module->operation_type(%params); 
  # Func_Module -- module in API/Plesk folder
  # operation_type -- sub which defined in Func_Module.
  # params hash used as @_ for operation_type sub.

=back

=cut


# sends request to Plesk API
sub send {
    my ( $self, $xml, %params ) = @_;

    confess "Wrong request data!" unless $xml && ref $xml;

    $xml = $self->render_xml($xml);
    $xml = qq|<?xml version="1.0" encoding="UTF-8"?><packet version="$self->{api_version}">$xml</packet>|;

    my ($response_xml, $error) = $self->xml_http_req($xml);

    unless ( $error ) {
        $response_xml = xml2hash $response_xml, array => ['result'];
    }    

    return ($response_xml, $error);
}

# Execue xml request to url
# STATIC
# $url: URL
# $request: text query
# %params:
sub xml_http_req {
    my ($self, $xml, %params) = @_;

    my $ua = new LWP::UserAgent( parse_head => 0 );
    my $req = new HTTP::Request POST => $self->{url};

    $req->push_header(':HTTP_AUTH_LOGIN',  $self->{username});
    $req->push_header(':HTTP_AUTH_PASSWD', $self->{password});
    $req->content_type('text/xml; charset=$params{charset}');
    $req->content($xml);

    my $res = eval {
        local $SIG{ALRM} = sub { die "connection timeout" };
        alarm $self->{timeout};
        $ua->request($req);
    };
    alarm 0;

    return('', 'connection timeout') 
        if !$res || $@ || ref $res && $res->status_line =~ /connection timeout/;

    return $res->is_success() ?
        ($res->content(), '') :
        ('', $res->status_line);
}


# renders xml from hash
sub render_xml {
    my ($self, $hash) = @_;

    return $hash unless ref $hash;

    my $xml = '';

    for my $tag ( keys %$hash ) {
        my $value = $hash->{$tag};
        if ( ref $value eq 'HASH' ) {
            $value = $self->render_xml($value);
        }
        elsif ( ref $value eq 'ARRAY' ) {
            my $tmp;
            $tmp .= $self->render_xml($_) for ( @$value );
            $value = $tmp;
        }
        elsif ( ref $value eq 'CODE' ) {
            $value = $self->render_xml(&$value);
        }
    
        if ( $value ) {
            $xml .= "<$tag>$value</$tag>";
        }
        else {
            $xml .= "<$tag/>";
        }
    }

    $xml; 
}

# creates access method to compoment
sub has_component {
    my ( $name ) = @_;

    my $pkg = caller;
    my $component_pkg = "$pkg\::$name";
    $name =~ s/^(.)/lc($1)/e;
    
    no strict 'refs';
    
    *{"$pkg\::$name"} = sub {
        my( $self ) = @_;
        $self->{"_$name"} ||= load_component($component_pkg);
        return $self->{"_$name"};
    }
}

# loads component package and creates object
sub load_component {
    my ( $pkg ) = @_;
    my $pkg = "$pkg.pm";
    $pkg =~ s/::/\//g;
    local $@;
    eval { require $pkg };
    if ( $@ ) {
        confess "Failed to load $pkg: $@!";
    }
    return $pkg->new;
}


# Check xml structure and find status block with error flag
# OLD
sub check_xml_answer {
    my ($self, $checked_xml, $parser_sub, $ext_params) = @_;
    warn $checked_xml;
    unless ($checked_xml) {
        return make_response('',
            'check_xml_answer: blank query to check_xml_answer'); 
    }
    
    unless (ref $parser_sub eq 'CODE') {
        return make_response('', 'check_xml_answer: no parser subref');
    }
    
    my $result = $parser_sub->($checked_xml, @$ext_params);
    
    my @errors;
    if (ref $result eq 'ARRAY') {
        for (@$result) {          
            if ($_->{errcode}) {
                for ($_->{errtext}) {
                    s/&quot;/"/sgio;
                }

                push @errors, "$_->{errcode}: $_->{errtext}";
            }
        }
    } elsif (ref $result eq 'HASH') {
        
        if ($result->{'errcode'}) {
            for ($result->{errtext}) {
                $result->{errtext} =~ s/&quot;/"/sgio;
            }

            push @errors, "$result->{'errcode'}: $result->{errtext}";
        }
        $result = [ $result ]; # construct arref of hashref
    }

    return scalar @errors ? make_response('', @errors) : make_response($result);
}

1;

__END__

=head1 SEE ALSO
 
Plesk XML RPC API  http://www.parallels.com/en/products/plesk/docs/

=head1 AUTHOR

Odintsov Pavel E<lt>nrg[at]cpan.orgE<gt>
Nikolay Shulyakovskiy E<lt>shulyakovskiy[at]rambler.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by NRG

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
