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

use API::Plesk::Response;

our $VERSION = '1.08';

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

  api_version -- default: 1.5.0.0
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
        api_version   => $params {api_version},
        username      => $params {username},
        password      => $params {password},
        url           => $params {url},
        debug         => $params {debug},
        package_name  => __PACKAGE__, # for parse $AUTLOAD.
        fake_response => '',
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


# Send "short" XML query to Plesk, 
# return Plesk::Responce object (with error handling)
# INSTANCE (query, parser_sub)
# query -- xml query
# parser_sub -- ref to parser sub
# ext_params -- arref, list of addition params for check_xml sub 
sub plesk_query {
    my ($self, $query, $parser_subref, $ext_params) = @_;

    return make_response('', 'plesk_query: blank request') unless $query;
    return make_response('', 'plesk_query: no parser subref') unless $parser_subref;

    $ext_params ||= '';

    return $self->check_xml_answer( $self->_execute_query($query) || '', $parser_subref, $ext_params);
}


# Short alias for creating Response object 
# STATIC (server_answer, errors)
sub make_response {
    my ($server_answer, @errors) = @_;

    return  API::Plesk::Response->new ($server_answer, @errors);
}


# Send XML query to Plesk, return not parsed XML answer without error handling
# INSTANCE(xml_request)
sub _execute_query {
    my ($self, $xml_request) = @_;

    # packet version override for 
    my $packet_version =  ($xml_request =~ m#<domain>.*?<add>#is) ?
        '1.4.2.0' : $self->{'api_version'};

    return unless $xml_request;
    my $xml_packet_struct = <<"    DOC";
        <?xml version="1.0" encoding="UTF-8"?>
        <packet version="$packet_version"> 
            $xml_request
        </packet>
    DOC

    return xml_http_req(
        $self->{'url'},
        $xml_packet_struct,

        headers => {
            ':HTTP_AUTH_LOGIN'  => $self->{'username'},
            ':HTTP_AUTH_PASSWD' => $self->{'password'},
        }
    );
}


# Check xml structure and find status block with error flag
# INSTANCE
sub check_xml_answer {
    my ($self, $checked_xml, $parser_sub, $ext_params) = @_;

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


# Select requested methods on the fly :)
# INSTANCE(category, operation_type, params)
# category -- Domains, Templates, Accounts
# operation_type -- create, modify, delete, get
# params -- arref params to sub
sub process_autoload_sub {
    my ($self, $category, $operation_type, $params) = @_;   

    no strict 'refs';

    my $sub_prefix = "$self->{package_name}::${category}::${operation_type}";
    my $parser_sub_prefix = $sub_prefix . '_response_parse';

    my $get_xml_sub_ref        = \&{$sub_prefix}; 
    my $response_parser_subref = \&{$parser_sub_prefix};
            
    unless (ref $get_xml_sub_ref eq 'CODE' &&
            ref $response_parser_subref eq 'CODE') {
        confess 'Error while loading $sub_prefix or $parser_sub_prefix !';
    }

    if ($self->{'fake_response'}) {
        return $self->check_xml_answer( $self->{'fake_response'}, 
            $response_parser_subref);
    }

    my $xml_request = $get_xml_sub_ref->(@$params);

    if ($self->{'request_debug'}) {
        return $self->_execute_query($xml_request); # return raw data
    }

    return $self->plesk_query($xml_request, $response_parser_subref, $params);
}

# Change methods on the fly :)
# INSTANCE
sub AUTOLOAD {
    my ($self, @params) = @_;
    
    if (our $AUTOLOAD !~ /DESTROY/) {
        my ($category, $operation_type) = 
            $AUTOLOAD =~ m/^$self->{'package_name'}::([a-z0-9]+)_([a-z0-9]+)$/i;        
            
        my ($required_package_name) =
            $AUTOLOAD =~ m/^$self->{'package_name'}::([a-z0-9]+)$/i;

        if ($required_package_name) {
            my $req_package = $self->{package_name} . 
                "::$required_package_name.pm";   
            
            $req_package =~ s#::#/#g;

            confess "Not found $required_package_name module!!"
                unless eval { require $req_package};

            no strict 'refs';
            no warnings 'redefine';

            foreach my $operation ('create', 'modify', 'delete', 'get') {
                *{"${required_package_name}::$operation"} = sub {
                    (undef) = shift if ref $_[0] eq $required_package_name;

                    return $self->process_autoload_sub(
                        $required_package_name,
                        $operation,
                        \@_
                    );
                };
            }

            return bless {}, $required_package_name;

        } else {

            confess "Sub $AUTOLOAD not found!";

        }
    }
}


# Execue xml request to url
# STATIC
# $url: URL
# $request: text query
# %params:
#   charset: source encoding
#   timeout: timeout, 10 seconds as default
#   headers: hashre -- header => value
#   error: array for status errors
#   errorbody: return erroneous request body to error array if defined  errorbody
sub xml_http_req {
    my ($url, $request, %params) = @_;

    $params{timeout} ||= 10;

    my $ua = new LWP::UserAgent( parse_head => 0 );
    my $req = new HTTP::Request POST => $url;

    my $content_type = 'text/xml';
    $content_type .= "; charset=$params{charset}" if $params{charset};
    $req->content_type($content_type);
    $req->content( $request );

    if ($params{headers} && ref $params{headers} eq 'HASH') {
        my $headers = $params{headers};
        foreach my $k (keys %$headers) {
            $req->push_header( $k, $headers->{$k} );
        }
    }

    my $res = eval {
        local $SIG{ALRM} = sub { die "connection timeout" };
        alarm $params{timeout};
        $ua->request($req);
    };

    alarm 0;
    return if !$res || $@ || 
                ref $res && $res->status_line =~ /connection timeout/;

    if ($res->is_success()) {
        return $res->content();
    } else {

        if ($params{errorbody}) {
            @{$params{error}} = ($res->status_line, $res->content);
        } else {
            warn "xml_http_req: ".$res->status_line;
        }
    }

    return;
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
