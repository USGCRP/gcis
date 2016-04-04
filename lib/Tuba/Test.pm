=head1 NAME

Tuba::Term : Controller class for test. (sample basic minimal route)

=cut

package Tuba::Test;
use Mojo::Base qw/Tuba::Controller/;
#use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    $c->render('test/list');
}

1;

