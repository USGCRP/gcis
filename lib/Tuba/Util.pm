=head1 NAME

Tuba::Util -- misc util functions

=cut

package Tuba::Util;
use String::Diff qw/diff/;
use Mojo::Base 'Exporter';
use Mojo::ByteStream qw/b/;

our @EXPORT_OK = qw/nice_db_error show_diffs/;

sub nice_db_error {
    my $err = shift or return;
    if ($err =~ s/DBD::Pg::st execute failed: //) {
        $err =~ s[ at /opt\S+Object.pm line \d+][];
        return $err;
    }
    return $err;
}

sub show_diffs {
    my ($x,$y) = @_;
    my ($old,$new) = diff($x,$y,
        remove_open => '<b class="removed">', remove_close => '</b>',
        append_open => '<b class="appended">', append_close => '</b>');
    return b($new);
}

1;

