=head1 NAME

Tuba::Region : Controller class for regions.

=cut

package Tuba::Region;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $report_id = $c->stash('report_identifier');
    my $pub_id = $c->stash('pub_id');
    my $count;
    my $objects;
    if ( $report_id || $pub_id ){
        my $publication;
        if ( $report_id ) {
            my $report = Report->new( identifier => $report_id );
            $publication = $report->get_publication();
        } elsif ( $pub_id ) {
            $publication = Publication->new( id => $pub_id );
        }
        $objects = Regions->get_objects(
            query => [ publication_id => $publication->id ],
            with_objects => [qw/publications/],
            page => $c->page,
            per_page => $c->per_page
        );
        $count = Regions->get_objects_count(
            query => [ publication_id => $publication->id ],
            with_objects => [qw/publications/],
        );
    }
    else {
        $objects = Regions->get_objects(
            with_objects => 'publications',
            page => $c->page,
            per_page => $c->per_page
        );
        $count = Regions->get_objects_count;
    }
    $c->stash(objects => $objects);
    $c->stash(extra_cols => [qw/label/]);
    $c->set_pages($count);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $kw = $c->_this_object or $c->reply->not_found;
    $c->stash(object => $kw);
    $c->SUPER::show(@_);
}

1;

