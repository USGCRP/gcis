=head1 NAME

Tuba::Finding : Controller class for findings.

=cut

package Tuba::Finding;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $objects;
    my $meta = Finding->meta;
    my $report_identifier = $c->stash('report_identifier');
    my $all = $c->param('all');
    my @page = $all ? () : (page => $c->page);

    if (my $chapter_identifier = $c->stash('chapter_identifier')) {
        $objects = Findings->get_objects(
            query => [chapter_identifier => $chapter_identifier, report_identifier => $report_identifier],
            with_objects => ['chapter'],
            @page,
            sort_by => "number, ordinal, t1.identifier");
        $c->title("Findings in report : $report_identifier, chapter $chapter_identifier");
        $c->set_pages(
            Findings->get_objects_count(
                query => [chapter_identifier => $chapter_identifier, report_identifier => $report_identifier],
                with_objects => ['chapter'],
            )
        ) unless $all;
    } else {
        $objects = Findings->get_objects(
            query => [ report_identifier => $report_identifier ],
            with_objects => ['chapter'],
            sort_by => "number, ordinal, t1.identifier",
            @page,
        );
        $c->set_pages(
            Findings->get_objects_count( query => [ report_identifier => $report_identifier ] )
        ) unless $all;
        $c->title("Findings in report $report_identifier");
    }

    $c->stash(objects => $objects);
    $c->stash(extra_cols => [ 'numeric' ]);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $meta = Finding->meta;
    my $identifier = $c->stash('finding_identifier');
    my $report_identifier = $c->stash('report_identifier');
    my $object = Finding->new( identifier => $identifier, report_identifier => $report_identifier )->load( speculative => 1)
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->SUPER::show(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Finding->meta->relationship($_), qw/keywords/ ]);
    $c->stash(controls => {
            keywords => sub {
                my ($c,$obj) = @_;
                +{
                    template => 'keywords',
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
    if (my $new = $c->param('new_keyword')) {
        my $kwd = Keyword->new_from_autocomplete($new);
        #$c->Tuba::Search::autocomplete_str_to_object($new);
        $object->add_keywords($kwd);
        $object->save(audit_user => $c->user) or do {
            $c->flash(error => $object->error);
            return $c->redirect_to($next);
        };
    }

    my $report_identifier = $c->stash('report_identifier');
    for my $id ($c->param('delete_keyword')) {
        next unless $id;
        FindingKeywordMaps->delete_objects({ keyword_id => $id, finding_identifier => $object->identifier, report_identifier => $report_identifier });
        $c->flash(message => 'Saved changes');
    }

    return $c->redirect_to($next);
}

1;

