=head1 NAME

Tuba::TermMap : Controller class for term mappings to gcids, via specific relationships 

=cut

package Tuba::TermMap;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

# Override the value returned in Controller.pm
sub _default_list_order {
    return "term_identifier";
}

1;
