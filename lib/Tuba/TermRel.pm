=head1 NAME

Tuba::TermRel : Controller class for term subject-predicate-object relationships

=cut

package Tuba::TermRel;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

# Override the value returned in Controller.pm
sub _default_list_order {
    return "term_subject";
}

1;
