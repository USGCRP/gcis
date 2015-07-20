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
    my $book = $c->_this_object or return $c->render_not_found_or_redirect;
    $c->stash('object', $book);
    $c->SUPER::show(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->SUPER::update_rel_form(@_);
}

sub update {
    my $c = shift;
    $c->stash(tab => 'update_form');
    my $book = $c->_this_object or return $c->reply->not_found;
    if ($c->param('convert_into_report')) {
        return $c->update_error("Not converting because this book has an ISBN, and reports don't have ISBNs.") if $book->isbn && length($book->isbn);
        my $report = Report->new(
            identifier => $book->identifier,
            title => $book->title,
            topic => $book->topic,
            url => $book->url,
            publication_year => $book->year
        );
        $report->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or do {
            return $c->update_error($report->error);
        };
        my $pub = $book->get_publication;
        if ($pub) {
            my $report_pub = $report->get_publication(autocreate => 1);
            $report_pub->save(audit_user => $c->audit_user, audit_note => $c->audit_note);
            my $refs = References->get_objects(query => [ child_publication_id => $pub->id ] );
            for my $ref (@$refs) {
                $ref->child_publication_id($report_pub->id);
                my $attrs = $ref->attrs; # workaround : call inflate trigger explicitly
                $ref->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($ref->error);
            }
            my $maps = PublicationReferenceMaps->get_objects(query => [ publication_id => $report_pub->id ]);
            for my $map (@$maps) {
                $map->publication_id($report_pub->id);
                $map->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($map->error);
            }
        }
        $book->delete;
        return $c->redirect_to( $report->uri($c, { tab => 'show' } ) );
    }
    $c->SUPER::update(@_);
}

1;

