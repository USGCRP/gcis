=head1 NAME

Tuba::ModelRun : Controller class for model runs.

=cut

package Tuba::ModelRun;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

=head1 show

Show metadata about a model run.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('model_run_identifier');
    my $object = ModelRun->new( identifier => $identifier )
                      ->load( speculative => 1 )
                          or return $c->reply->not_found;
    $c->stash(object => $object);
    $c->stash(meta => ModelRun->meta);
    $c->SUPER::show(@_);
}

sub list {
    my $c = shift;
    if (my $model = $c->stash('model_identifier')) {
        my $objects = ModelRuns->get_objects(
                sort_by => "identifier",
                page => $c->page,
                per_page => $c->per_page,
                query => [ model_identifier => $model ]
            );
        my $object_count = ModelRuns->get_objects_count(
                query => [ model_identifier => $model ]
        );
        $c->set_pages($object_count);
        $c->stash(objects => $objects);
    }
    if (my $scenario = $c->stash('scenario_identifier')) {
        my $objects = ModelRuns->get_objects(
                sort_by => "identifier",
                page => $c->page,
                per_page => $c->per_page,
                query => [ scenario_identifier => $scenario ]
            );
        my $object_count = ModelRuns->get_objects_count(
                query => [ scenario_identifier => $scenario ]
        );
        $c->set_pages($object_count);
        $c->stash(objects => $objects);
    }
    return $c->SUPER::list(@_);
}

sub lookup {
    my $c = shift;

    my $run = ModelRun->new(
      model_identifier    => $c->stash('model_identifier'),
      scenario_identifier => $c->stash('scenario_identifier'),
      spatial_resolution  => $c->stash('spatial_resolution'),
      time_resolution     => $c->stash('time_resolution'),
      range_start         => $c->stash('range_start'),
      range_end           => $c->stash('range_end'),
      sequence            => $c->stash('sequence'),
    );

    if (my $error = $run->db->error) {
        return $c->redirect_with_error( show => $error );
    }
    $run->load( speculative => 1 ) or do {
        return $c->reply->not_found;
    };
    return $c->redirect_to("/model_run/".$run->identifier);
}


1;

