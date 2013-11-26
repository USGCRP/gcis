=head1 NAME

Tuba::Table : Controller class for tables.

=cut

package Tuba::Table;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $tables;
    my $report_identifier = $c->stash('report_identifier');
    my $all = $c->param('all');
    my @page = $all ? () : (page => $c->page);
    if (my $ch = $c->stash('chapter_identifier')) {
        $tables = Tables->get_objects(
            query => [chapter_identifier => $ch, report_identifier => $report_identifier], with_objects => ['chapter'],
            @page,
            sort_by => "number, ordinal, t1.identifier",
            );
        $c->set_pages(Tables->get_objects_count(
            query => [chapter_identifier => $ch, report_identifier => $report_identifier], with_objects => ['chapter'],
            )) unless $all;
    } else {
        $tables = Tables->get_objects(
           with_objects => ['chapter'], sort_by => "number, ordinal, t1.identifier",
           query => [ report_identifier => $report_identifier ],
           @page,
       );
       $c->set_pages(Tables->get_objects_count(
           query => [ report_identifier => $report_identifier ])
       ) unless $all;
    }
    
    $c->stash(objects => $tables);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $report_identifier = $c->stash('report_identifier');
    my $identifier = $c->stash('table_identifier');
    my $meta = Table->meta;
    my $object = Table->new(identifier => $identifier, report_identifier => $report_identifier)
        ->load(speculative => 1, with => [qw/chapter arrays/]) or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
}

sub redirect_to_identifier {
    my $c = shift;
    my $chapter_number = $c->stash('chapter_number');
    my $table_number = $c->stash('table_number');
    my $found = Tables->get_objects(
            with_objects => ['chapter'],
            query => [
                'chapter.number' => $chapter_number,
                'ordinal' => $table_number,
            ]
        );
    return $c->render_not_found unless $found && @$found;
    return $c->redirect_to( 'show_table' => { table_identifier => $found->[0]->identifier } );
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Table->meta->relationship($_), qw/arrays/ ]);
    $c->stash(controls => {
            arrays => sub {
                my ($c,$obj) = @_;
                +{
                    template => 'arrays',
                    params => { }
                  }
              }
        });
    $c->SUPER::update_rel_form(@_);
}

sub update_rel {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    my $next = $object->uri($c,{tab => 'update_rel_form'});
    $object->meta->error_mode('return');
    if (my $new = $c->param('make_array')) {
        my $array = Array->new();
        $object->add_arrays($array);
        $object->save(audit_user => $c->user) or do {
            $c->flash(error => $object->error);
            return $c->redirect_to($next);
        };
    }

    my $report_identifier = $c->stash('report_identifier');
    for my $id (grep { defined && length } $c->param('delete_array')) {
        ArrayTableMaps->delete_objects({ array_identifier => $id, table_identifier => $object->identifier, report_identifier => $report_identifier });
        my $array = Array->new(identifier => $id);
        $array->load;
        if (!@{ $array->tables }) {
            $array->delete;
            $c->flash(message => 'Deleted array');
        } else {
            $c->flash(message => 'Deleted array for this table');
        }
    }

    return $c->SUPER::update_rel(@_);
}

1;

