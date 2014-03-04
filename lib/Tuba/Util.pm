=head1 NAME

Tuba::Util -- misc util functions

=cut

package Tuba::Util;
use String::Diff qw/diff/;
use Mojo::Base 'Exporter';
use Mojo::ByteStream qw/b/;
use Mojo::Util qw/xml_escape/;
use Encode qw/decode/;

our @EXPORT_OK = qw/nice_db_error set_config get_config show_diffs elide_str/;

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
        append_open => '<b class="appended">', append_close => '</b>',
        escape => \&xml_escape
    );
    return b($new);
}

{
my $conf;
sub set_config {
    my $new_conf = shift;
    $conf = $new_conf;
    return $conf;
}
sub get_config {
    return $conf->{$_[0]} if @_==1;
    $conf;
}
}

sub elide_str {
    my $str = shift;
    my $len = shift or die "missing length";
    return $str if !$str || length($str) < $len;
    return substr($str,0,$len-3).'...';
}

1;

