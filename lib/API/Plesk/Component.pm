package API::Plesk::Component;

use strict;
use warnings;

use Carp;

sub new {
    my ( $class, %attrs ) = @_;
    $class = ref $class || $class;

    confess "Required API::Plesk object!" unless $attrs{plesk};

    return bless \%attrs, $class;
}

sub plesk { $_[0]->{plesk} }

sub check_required_params {
    my ( $self, $hash, @fields ) = @_;
    
    for ( @fields ) {
        confess "Required field $_!" unless exists $hash->{$_};
    }
}

1;
