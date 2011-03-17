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
    
    for my $key ( @fields ) {
        if ( ref $key ) {
            confess "Required any of this fields: " . join( ", ", @$key) . "!"
                unless grep { $hash->{$_} } @$key;
        } else {
            confess "Required field $key!" unless exists $hash->{$key};
        }
    }
}

# sort params in right order
sub sort_params {
    my ( $self, $params, @fields ) = @_;

    my @sorted;
    for ( @fields ) {
        push @sorted, {$_ => $params->{$_}}
            if exists $params->{$_};
    }
    return \@sorted;
}

1;
