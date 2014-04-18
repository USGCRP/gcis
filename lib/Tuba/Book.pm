=head1 NAME

Tuba::Book : Controller class for books

=cut

package Tuba::Book;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    $c->stash(extra_cols => [qw/title number_of_pages/]);
    if ($c->param('in_library')) {
        my $objects = Books->get_objects(query => [ in_library => 1 ],
            ($c->param('all')
          ? ()
          : (page => $c->page, per_page => $c->per_page)),
          sort_by => 'identifier'
        );
        my $count = Books->get_objects_count({ in_library => 1});
        $c->stash(objects => $objects);
        $c->set_pages($count);
    }
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    $c->stash('object', $c->_this_object);
    $c->SUPER::show(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->SUPER::update_rel_form(@_);
}

sub update {
    my $c = shift;
    if ($c->param('convert_into_report')) {
        return $c->render(text => 'sorry, not implemented');
    }
    $c->SUPER::update(@_);
}

1;

