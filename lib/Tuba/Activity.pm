=head1 NAME

Tuba::Activity : Controller class for books

=cut

package Tuba::Activity;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use JSON::XS;

sub list {
    my $c = shift;
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    $c->stash('object', $c->_this_object);
    $c->SUPER::show(@_);
}

sub create {
    my $c = shift;
    my $spatial_extent = $c->_spatial_extent;
    my $error = _check_valid_geojson($spatial_extent) if $spatial_extent;
    return $c->create_error($error) if $error;
    $c->SUPER::create(@_);
}

sub update {
    my $c = shift;
    my $spatial_extent = $c->_spatial_extent;
    my $error = _check_valid_geojson($spatial_extent) if $spatial_extent;
    return $c->update_error($error) if $error;
    $c->SUPER::update(@_);
}

sub make_tree_for_show {
    my $c = shift;
    my $obj = shift;
    my $tree = $obj->as_tree(c => $c,
        ( $c->param('brief') ? (bonsai => 1) : ()),
        ( $c->param('with_gcmd') ? (with_gcmd => 1) : ())
    );
    $tree->{methodologies} = [
        map $_->as_tree(c => $c), $obj->methodologies
    ];
    $tree->{publication_maps} = [
        map $_->as_tree, $obj->publication_maps
    ];
    return $tree;
}

sub normalize_form_parameter {
    my $c = shift;
    my %args = @_;
    my ($column, $value) = @args{qw/column value/};
    my $obj;
    for ($column) {
        /^methodology_publication_id$/ and $obj = $c->str_to_obj($value);
        /^output_publication_id$/ and $obj = $c->str_to_obj($value);
    }
    if ($obj) {
        my $pub = $obj->get_publication(autocreate => 1);
        $pub->save(audit_user => $c->audit_user, audit_note => $c->audit_note) unless $pub->id;
        return $pub->id;
    }
    return $value;
}

sub _default_order {
    my $c = shift;
    return ( qw/
        identifier
        methodology
        visualization_methodology
        methodology_citation
        methodology_contact
        activity_duration
        source_access_date
        source_modifications
        modified_source_location
        interim_artifacts
        output_artifacts
        computing_environment
        software
        visualization_software
        start_time
        end_time
        database_variables
        spatial_extent
        data_usage
        notes
        methodology_publication_id
        methodology_contributor_id/
    );
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [qw/methodologies/]);
    return $c->SUPER::update_rel_form(@_);
}

sub _default_rel_controls  {
    my $c = shift;
    return ($c->SUPER::_default_controls(@_),
        methodologies => sub {
            my $c = shift;
            { template => 'publications', params => { method => 'methodologies' } }
        },
    );
}

sub update_rel {
    my $c = shift;
    my $activity = $c->_this_object;
    $c->stash(tab => 'update_rel_for');

    # TODO handle JSON
    if (my $new = $c->param('new_publication')) {
        my $obj = $c->str_to_obj($new);
        my $pub = $obj->get_publication(autocreate => 1);
        $pub->save(audit_user => $c->audit_user, audit_note => $c->audit_note) unless $pub->id;
        my $methodology = Methodology->new(
            activity_identifier => $activity->identifier,
            publication_id => $pub->id
        );
        $methodology->save(audit_user => $c->audit_user, audit_note => $c->audit_note)
            or return $c->update_error($methodology->error);
    }
    for my $id ($c->param('delete_publication')) {
        next unless $id;
        Tuba::DB::Object::Methodology::Manager->delete_objects(
            { activity_identifier => $activity->identifier,
              publication_id => $id });
        $c->flash(message => 'Saved changes');
    }

    $c->respond_to(
        json => sub {
            shift->render(json => { status => 'ok' })
        },
        html => sub {
            return shift->redirect_without_error('update_rel_form');
        },
    );
}

sub _spatial_extent {
    my $c = shift;
    return $c->param('spatial_extent') if $c->param('spatial_extent');

    my $json = $c->req->json;
    return unless $json;
    return $json->{spatial_extent};

}

# TODO finalize the feedback based on JSON vs Param.
# maybe do distinct wrappers for JSON/param?
sub _check_valid_geojson {
    my $spatial_param = shift;
    my $valid_geojson_types = {
        Point              => 1,
        MultiPoint         => 1,
        LineString         => 1,
        MultiLineString    => 1,
        Polygon            => 1,
        MultiPolygon       => 1,
        GeometryCollection => 1,
        Feature            => 1,
        FeatureCollection  => 1,
    };
    # parse valid JSON
    my $error;
    my $geojson = eval { JSON::XS->new->decode($spatial_param); };
    if ($@ || (ref $geojson ne 'HASH')) {
        $error = "Invalid geoJSON: could not parse json :".($@ || ref $geojson);
    }
    # check the field type exists
    if ( !$error && $geojson->{'type'} ) {
        # check the type value is valid
        unless ( $valid_geojson_types->{ $geojson->{'type'} } ) {
            $error = "Invalid geoJSON: Bad type '$geojson->{type}' not one of 'Point', 'MultiPoint', 'LineString', 'MultiLineString', 'Polygon', 'MultiPolygon', or 'GeometryCollection'";
        }
    }
    else {
        $error = "Invalid geoJSON: missing type field" unless $error;
    }

    return $error;
}

1;

