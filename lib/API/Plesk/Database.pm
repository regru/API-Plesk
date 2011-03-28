
package API::Plesk::Database;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

sub add_db {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};

    $self->check_required_params(\%params, qw(webspace-id name type));
     
    return $bulk_send ? \%params : 
        $self->plesk->send('database', 'add-db', \%params);
}

sub del_db {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('database', 'del-db', $data);
}

sub add_db_user {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};

    $self->check_required_params(\%params, qw(db-id login password));
    
    return $bulk_send ? \%params : 
        $self->plesk->send('database', 'add-db-user', \%params);
}

sub del_db_user {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('database', 'del-db-user', $data);
}

1;
