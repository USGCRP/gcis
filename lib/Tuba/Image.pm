=head1 NAME

Tuba::Image : Controller class for images.

=cut

package Tuba::Image;
use Mojo::Base qw/Tuba::Controller/;
use File::Temp;
use YAML::XS qw/DumpFile LoadFile/;
use Path::Class qw/file dir/;
use File::Basename qw/basename/;
use Tuba::Log;
use Tuba::DB::Objects qw/-nicknames/;
use Data::UUID::LibUUID;

=head1 ROUTES

=head1 show

Show metadata about an image.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('image_identifier');
    my $meta = Image->meta;
    my $object = Image->new( identifier => $identifier )
      ->load( speculative => 1, with => [qw/figures/] )
      or return $c->render_not_found_or_redirect;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Image->meta->relationship($_), qw/figures/ ]);
    $c->stash(controls => {
            figures => sub {
                my ($c,$obj) = @_;
                +{ template => 'figure', params => { no_thumbnails => 1 } }
              },
        });
    $c->SUPER::update_rel_form(@_);
}

sub update_rel {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
    $object->meta->error_mode('return');
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);

    if (my $new = $c->param('new_figure')) {
        my $img = $c->Tuba::Search::autocomplete_str_to_object($new);
        $object->add_figures($img);
        $object->save(audit_user => $c->user) or do {
            $c->flash(error => $object->error);
            return $c->update_rel_form(@_);
        };
    }

    for my $id ($c->param('delete_figure')) {
        ImageFigureMaps->delete_objects({ figure_identifier => $id, image_identifier => $object->identifier });
        $c->flash(message => 'Saved changes');
    }

    return $c->SUPER::update_rel(@_);
}

sub create_form {
    my $c = shift;
    $c->param(identifier => new_uuid_string(4));
    return $c->SUPER::create_form(@_);
}

sub list {
    my $c = shift;
    my $report = $c->stash('report_identifier') or return $c->SUPER::list(@_);
    my $all = $c->param('all');
    my @page = $all ? () : (page => $c->page, per_page => $c->per_page);
    $c->stash(objects => Images->get_objects(
        query => [report_identifier => $report ],
        require_objects => [qw/figures/],
        @page
    ));
    $c->set_pages( Images->get_objects_count(
        query => [report_identifier => $report ],
        require_objects => [qw/figures/],
    ));
    return $c->SUPER::list(@_);
}

1;

