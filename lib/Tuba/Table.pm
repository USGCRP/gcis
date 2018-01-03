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
    my @page = $all ? () : (page => $c->page, per_page => $c->per_page);
    if (my $ch = $c->stash('chapter')) {
        $tables = Tables->get_objects(
            query => [chapter_identifier => $ch->identifier, report_identifier => $report_identifier], with_objects => ['chapter'],
            @page,
            sort_by => "number, ordinal, t1.identifier",
            );
        $c->set_pages(Tables->get_objects_count(
            query => [chapter_identifier => $ch->identifier, report_identifier => $report_identifier], with_objects => ['chapter'],
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

sub set_title {
    my $c = shift;
    if (my $ch = $c->stash('chapter')) {
        $c->stash(title => sprintf("Tables in chapter %s of %s",$ch->stringify(tiny => 1), $ch->report->title));
    } else {
        $c->stash(title => sprintf("Tables in %s",$c->stash('report')->title));
    }
}

sub show {
    my $c = shift;
    my $report_identifier = $c->stash('report_identifier');
    my $identifier = $c->stash('table_identifier');
    my $meta = Table->meta;
    my $object = Table->new(identifier => $identifier, report_identifier => $report_identifier)
        ->load(speculative => 1, with => [qw/chapter arrays/]);
    if (!$object && ($identifier =~ /^[0-9]+[0-9a-zA-Z._-]*$/) && $c->stash('chapter') ) {
        my $chapter = $c->stash('chapter');
        $object = Table->new(
          report_identifier  => $c->stash('report_identifier'),
          chapter_identifier => $chapter->identifier,
          ordinal            => $identifier,
        )->load(speculative => 1, with => [qw/chapter arrays/]);
        return $c->redirect_to($object->uri_with_format($c)) if $object;
    };
    return $c->reply->not_found unless $object;

    if (!$c->stash('chapter_identifier') && $object->chapter_identifier) {
        $c->stash(chapter_identifier => $object->chapter_identifier);
    }
    return $c->reply->not_found unless $c->verify_consistent_chapter($object);

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
    return $c->reply->not_found unless $found && @$found;
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

sub update_form {
     my $c = shift;
     my $object = $c->_this_object or return $c->reply->not_found;
     $c->verify_consistent_chapter($object) or return $c->reply->not_found;
     $c->SUPER::update_form(@_);
}

sub update_rel {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
    $c->stash(tab => "update_rel_form");
    my $json = $c->req->json;

    my $next = $object->uri($c,{tab => 'update_rel_form'});
    $object->meta->error_mode('return');

    if (my $new = $c->param('new_array')) {
        my $array = $c->Tuba::Search::autocomplete_str_to_object($new);
        $object->add_arrays($array);
        $object->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or do {
            $c->flash(error => $object->error);
            return $c->redirect_to($next);
        };
    }
    if (my $new = $json->{add_array_identifier}) {
        my $img = Array->new(identifier => $new)->load(speculative => 1)
            or return $c->update_error("array $new not found");
        $object->add_arrays($img);
        $object->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($object->error);
    }

    my $report_identifier = $c->stash('report_identifier');
    for my $id (grep { defined && length } $c->param('delete_array')) {
        ArrayTableMaps->delete_objects({ array_identifier => $id, table_identifier => $object->identifier, report_identifier => $report_identifier });
        my $array = Array->new(identifier => $id);
        $array->load;
        if (!@{ $array->tables }) {
            $array->delete(audit_user => $c->audit_user, audit_note => $c->audit_note);
            $c->flash(message => 'Deleted array');
        } else {
            $c->flash(message => 'Deleted array for this table');
        }
    }

    return $c->SUPER::update_rel(@_);
}


1;

