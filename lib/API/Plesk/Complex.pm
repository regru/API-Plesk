#
# DESCRIPTION:
#   Plesk communicate interface. Complex methods.
# AUTHORS:
#   Pavel Odintsov (nrg) <pavel.odintsov@gmail.com>
#
#========================================================================


package API::Plesk::Complex;

use strict;
use warnings;
use lib qw(../../..);

use API::Plesk;
use API::Plesk::Response;

our $VERSION = '1.03';

=head1 NAME

API::Plesk::Complex includes functions to perform complex operations, such as changing the tariff plan.

=head1 SYNOPSIS

  use API::Plesk::Complex;

  my $result = API::Plesk::Complex::change_tariff(
    $plesk_client,                # Plesk.pm object.
    from => 'source_tariff_name', # source tariff
    to => 'result_tarif_name',    # result tariff
    id => 'client_id_in_plesk'    # client id in Plesk
  );

  # $result -- API::Plesk::Response object.

=head1 DESCRIPTION

There are currently enforced only change tariff plan on the basis of permits and limitations specified in the Template
with the names in "to" and "from" fields.


We have Plesk feature - a shift from "high" (ie, with a large disk space, large number subdomains etc.)
to a "low" is not allowed and will get an error. So tentatively better check tariffs on "the possibility of transferring" first in Plesk administrative panel, and then use the automatic shift.

=head1 EXPORT

None.

=cut

# Migration from low tariff to high -- allowed,
# but migration from hight to low -- prohibited !!!!
sub change_tariff {
    my ($plesk_client, %params) = @_;
    my %data = ( );

    unless ($plesk_client &&
            $params{to}   &&
            $params{from} &&
            $params{id}
    ) {
        return API::Plesk::Response->new('', 'Not enought data for tariff change!');
    }

    # Get result template data
    my $result_template_get_query = $plesk_client->Templates->get(
        name => $params{to},
        type => 'account'
    );

    return API::Plesk::Response->new('', 'Get result template data failed')
        unless $result_template_get_query->is_success;

    $data{result_limits} = $result_template_get_query->get_data->[0]->{limits};
    $data{result_permissions} = $result_template_get_query->get_data->[0]->{permissions};   

    # Get source template data
    my $source_template_get_query = $plesk_client->Templates->get(
        name => $params{from},
        type => 'account'
    );

    return API::Plesk::Response->new('', 'Get source template data failed')
        unless $source_template_get_query->is_success;

    $data{source_limits}      = $source_template_get_query->get_data->[0]->{limits};
    $data{source_permissions} = $source_template_get_query->get_data->[0]->{permissions};

    # Compare limits blocks
    {
        foreach my $key (keys %{$data{source_limits}}) {
            if ($data{result_limits}->{$key}) {
                if ($data{result_limits}->{$key} eq '-1' or $data{source_limits}->{$key} eq '-1') {
                    # Unlim values
                    if ($data{result_limits}->{$key} eq '-1' and $data{source_limits}->{$key} eq '-1') {
                        # all ok!
                    } else {
                        if ($data{result_limits}->{$key} eq '-1') {
                            # all ok!
                        } else {
                            return API::Plesk::Response->new('', "Unlim -> limited value disallowed");
                        }
                    }
                } else {
                    # warn "$key source:", $data{source_limits}->{$key}, " result:", $data{result_limits}->{$key};
                    return  API::Plesk::Response->new('', 'Error, new limit < source limit!') 
                        if  $data{result_limits}->{$key} < 
                            $data{source_limits}->{$key}; # disabled!
                }
            }
        }
    }

    my $result_template_modify = $plesk_client->Accounts->modify(
        id => $params{id},
        limits => $data{result_limits},     
        permissions => $data{result_permissions},
    );
    
    return $result_template_modify;
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
