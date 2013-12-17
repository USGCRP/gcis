=head1 NAME

Tuba::Util -- misc util functions

=cut

package Tuba::Util;
use Mojo::Base 'Exporter';

our @EXPORT_OK = qw/nice_db_error/;

sub nice_db_error {
    my $err = shift or return;
    if ($err =~ s/DBD::Pg::st execute failed: //) {
        $err =~ s[ at /opt\S+Object.pm line \d+][];
        return $err;
    }
    return $err;
}

1;

