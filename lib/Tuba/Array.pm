=head1 NAME

Tuba::Array : Controller class for arrays.

=cut

package Tuba::Array;
use Mojo::Base qw/Tuba::Controller/;
use File::Temp;
use YAML::XS qw/DumpFile LoadFile/;
use Path::Class qw/file dir/;
use File::Basename qw/basename/;
use Tuba::Log;
use Tuba::DB::Objects qw/-nicknames/;
use Data::UUID::LibUUID;
use Text::CSV_XS;

=head1 ROUTES

=head1 show

Show metadata about an array.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('array_identifier');
    my $meta = Array->meta;
    my $object = Array->new( identifier => $identifier )
      ->load( speculative => 1, with => [qw/tables/] )
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
}

=head1 list

Show arrays for selected report.

=cut

sub list {
    my $c = shift;
    my $identifier = $c->current_report->identifier;
    my $page = $c->page;
    my $limit = 20;
    my $offset = ( $page - 1 ) * 20;
    if ($c->param('all')) {
        $limit = 10_000;
        $offset = 0;
    }
    my $objects = Arrays->get_objects_from_sql(
        args => [ $identifier, $identifier ],
        sql => qq[select i.*
        from "array" i
            inner join array_table_map m on m.array_identifier = i.identifier
            inner join "table" f on f.identifier = m.table_identifier
            inner join chapter c on f.chapter_identifier = c.identifier
        where c.report_identifier = ? or f.report_identifier = ?
        order by c.number,f.ordinal
        limit $limit offset $offset ]
    );
    unless ($c->param('all')) {
        $c->dbs->query('select count(1) from
            "array" i
                inner join array_table_map m on m.array_identifier = i.identifier
                inner join "table" f on f.identifier = m.table_identifier
                inner join chapter c on f.chapter_identifier = c.identifier
            where c.report_identifier = ? or f.report_identifier = ?
            ',$identifier,$identifier)->into(my $count);
        $c->set_pages($count);
    }
    $c->stash(objects => $objects);
    $c->SUPER::list(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Array->meta->relationship($_), qw/tables/ ]);
    $c->stash(controls => {
            tables => sub {
                my ($c,$obj) = @_;
                +{ template => 'table', params => { no_thumbnails => 1 } }
              },
        });
    $c->SUPER::update_rel_form(@_);
}

sub update_rel {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $object->meta->error_mode('return');
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);

    if (my $new = $c->param('new_table')) {
        my $img = $c->Tuba::Search::autocomplete_str_to_object($new);
        $object->add_tables($img);
        $object->save(audit_user => $c->user) or do {
            $c->flash(error => $object->error);
            return $c->update_rel_form(@_);
        };
    }

    for my $id ($c->param('delete_table')) {
        ArrayFigureMaps->delete_objects({ table => $id, array => $object->identifier });
        $c->flash(message => 'Saved changes');
    }

    $c->_redirect_to_view($object);
}

sub create_form {
    my $c = shift;
    $c->param(identifier => new_uuid_string(4));
    $c->stash(controls => {
            rows => { template => 'grid' }
        });
    return $c->SUPER::create_form(@_);
}

sub update_form {
    my $c = shift;
    $c->stash(controls => {
            rows => { template => 'grid' }
        });
    return $c->SUPER::update_form(@_);
}

sub _process_rows {
    # Returns an array ref on success, 0 for nothing to do, -1 for error.
    my $c = shift;
    my $file = $c->req->upload('rows.array_upload');
    return 0 unless $file;
    return 0 unless $file->size;
    my $format = $c->param('rows.array_upload_format');
    my $content = $file->asset->slurp;
    my @array;
    if ($format eq 'json') {
        my $ary = eval { JSON::XS->new->decode($content); };
        if ($@ || (ref $ary ne 'ARRAY')) {
            $c->flash(error => "could not parse json :".($@ || ref $ary));
            return -1;
        }
        @array = @$ary;
    } else {
        my %opts;
        $opts{sep_char} = "\t" if $format eq 'tsv';
        my $csv = Text::CSV_XS->new({binary => 1, allow_whitespace => 1, %opts});
        for my $line (split /\n\r?/, $content) {
            $csv->parse($line) or do {
                $c->flash(error => $csv->error_diag);
                return -1;
            };
            push @array, [ $csv->fields ];
        }
    }
    return \@array;
}

sub update {
    my $c = shift;
    my $obj = $c->_this_object or return $c->render_not_found;
    if (my $in = $c->_process_rows) {
        if (ref $in eq 'ARRAY') {
            $c->stash(computed_params => { rows => $in } );
        } else {
            return $c->redirect_to(Array->uri($c,{tab => 'update_form'}));
        }
    } elsif ($c->detect_format eq 'html') {
        $c->stash(computed_params => { rows => scalar $obj->rows });
    }

    $c->SUPER::update(@_);
}

sub create {
    my $c = shift;
    if (my $in = $c->_process_rows) {
        if (ref $in eq 'ARRAY') {
            $c->stash(computed_params => { rows => $in } );
        } else {
            return $c->redirect_to(Array->uri($c,{tab => 'create_form'}));
        }
    }

    $c->SUPER::create(@_);
}

1;

