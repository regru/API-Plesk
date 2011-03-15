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

sub make_request_data {
    my ( $self, $operator, $operation, @data ) = @_;

    my $request = [];
    for my $data ( @data ) {
        push @$request, { $operation => $data };
    }

    return { $operator => $request };
}

1;
