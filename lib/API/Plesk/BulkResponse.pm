
package API::Plesk::BulkResponse;

use strict;
use warnings;

use Data::Dumper;

#TODO


sub new {
    my ( $class, %attrs) = @_;
    $class = ref $class || $class;
    
    my $operator  = $attrs{operator};
    my $operation = $attrs{operation};
    my $response  = $attrs{response};
    my @results;
    my $is_success = 1;
    
    # internal API::Plesk error
    if ( $attrs{error} ) {
        @results = ({
            errcode => '',
            errtext => $attrs{error},
            status  => 'error'
        });
        $is_success = '';
    }
    # remote system plesk error
    elsif ( exists $response->{packet}->{'system'} ) {
        $results[0] = $response->{packet}->{'system'};
        $is_success = '';
        $operator   = 'system';
        $operation  = '';
    }
    else {

        $response = $response->{packet}->{$operator};

        for my $operations ( @{$response->{$operation}} ) {
            for my $result ( @{$operations->{result}} ) {
                $is_success = '' if $result->{status} eq 'error';
                push @results, $result;
            }
        }

    }
    
    my $self = {
        result     => \@results,
        operator   => $operator,
        operation  => $operation,
        is_success => $is_success,
    };

    return bless $self, $class;
}

sub is_success { $_[0]->{is_success} }

sub data {
    my ( $self ) = @_;
    return unless $self->is_success;
    unless ( $self->{data} ) {
        my @data;
        for ( @{$self->{result}} ) {
            push @data, $_->{data};
        }
        $self->{data} = \@data;
    }
    return @{$self->{data}} == 1 ? $self->{data}->[0] : $self->{data};
}

sub result { 
    my ( $self ) = @_;
    return undef unless $self->is_success;
    return @{$self->{result}} == 1 ? $self->{result}->[0] : $self->{result};
}

sub error_codes {
    my ( $self ) = @_;

    my @codes = map { ($_->{errcode}) || () } @{$self->{result}};

    return wantarray ? @codes : join ", ", @codes;
}

sub error_texts {
    my ( $self ) = @_;

    my @texts = map { ($_->{errtext}) || () } @{$self->{result}};

    return wantarray ? @texts : join ", ", @texts;
}

sub errors {
    my ( $self ) = @_;

    my @errors = map { 
        $_->{errcode} || $_->{errtext} ? 
            ("$_->{errcode}: $_->{errtext}") :
            () 
        } @{$self->{result}};

    return wantarray ? @errors : join ", ", @errors;
}

1;

