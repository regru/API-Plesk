
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
=cut

package API::Plesk;

use strict;
use warnings;
use lib qw(../..);

use Data::Dumper;
use Carp;

use HTTP::Request;
use LWP::UserAgent;
use XML::Fast;

use API::Plesk::Response;

our $VERSION = '2.00';

our %COMPONENTS = (
    'new' => [
        { class => 'Customers' },
    ],
    'old' => [
        { class => 'Accounts', alias => 'Accounts' },
    ]
);

=item new(%params)

Create new class instance.

Required params:

  api_version -- default: 1.6.3.0
  username -- Plesk user name.
  password -- Plesk password.
  url -- full url to Plesk XML RPC gate (https://ip.ad.dr.ess:8443/enterprise/control/agent.php).

=cut
sub new {
    my $class = shift;

    $class = ref ($class) || $class;
    
    my $self = { 
        api_version => '1.6.3.0',
        debug       => 0,
        timeout     => 10,
        (@_)
    };

    confess "Required username!" unless $self->{username};
    confess "Required password!" unless $self->{password};
    confess "Required url!" unless $self->{url};

    # add accessors to components
    my $components = 
        version->parse($self->{api_version}) < version->parse('v1.6.3.0') ?
        $COMPONENTS{'old'} : $COMPONENTS{'new'};

    $class->add_component(%$_) for @$components;
 
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
    my ( $self, $operator, $operation, $data, %params ) = @_;

    confess "Wrong request data!" unless $data && ref $data;

    my $xml = { $operator => { $operation => $data } };

    $xml = $self->render_xml($xml);

    warn "REQUEST $operator => $operation\n$xml" if $self->{debug};

    my ($response, $error) = $self->xml_http_req($xml);

    warn "RESPONSE $operator => $operation => $error\n$response" if $self->{debug};

    unless ( $error ) {
        $response = xml2hash $response, array => ['result', $operation];
    }    

    return API::Plesk::Response->new(
        operator  => $operator,
        operation => $operation,
        response  => $response,
        error     => $error,
    );
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

    return ('', 'connection timeout') 
        if !$res || $@ || ref $res && $res->status_line =~ /connection timeout/;

    return $res->is_success() ?
        ($res->content(), '') :
        ('', $res->status_line);
}


# renders xml from hash
sub render_xml {
    my ($self, $hash) = @_;

    my $xml = _render_xml($hash);

    $xml = qq|<?xml version="1.0" encoding="UTF-8"?><packet version="$self->{api_version}">$xml</packet>|;

    $xml;
}

sub _render_xml {
    my ( $hash ) = @_;

    return $hash unless ref $hash;

    my $xml = '';

    for my $tag ( keys %$hash ) {
        my $value = $hash->{$tag};
        if ( ref $value eq 'HASH' ) {
            $value = _render_xml($value);
        }
        elsif ( ref $value eq 'ARRAY' ) {
            my $tmp;
            $tmp .= _render_xml($_) for ( @$value );
            $value = $tmp;
        }
        elsif ( ref $value eq 'CODE' ) {
            $value = _render_xml(&$value);
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

# creates accessors to compoment
sub add_component {
    my ( $class, %params ) = @_;
    my $name = $params{class};
    
    my $component_pkg = "$class\::$name";
    $name =~ s/^(.)/lc($1)/e;

    return if $class->can($name);
    
    my $sub = sub {
        my( $self ) = @_;
        $self->{"_$name"} ||= $self->load_component($component_pkg);
        return $self->{"_$name"};
    };
    
    no strict 'refs';

    *{"$class\::$name"} = $sub;
}

# loads component package and creates object
sub load_component {
    my ( $self, $pkg ) = @_;
    my $module = "$pkg.pm";
    $module =~ s/::/\//g;
    local $@;
    eval { require $module };
    if ( $@ ) {
        confess "Failed to load $pkg: $@";
    }
    return $pkg->new(plesk => $self);
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
