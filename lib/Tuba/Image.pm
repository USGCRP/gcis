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

=head1 ROUTES

=head2 list

Get a list of images.

=cut

=head2 setmet

Upload metadata for this image.  Write two files : met.yaml, atrac.xml, into
a subdirectory of a directory named after the image identifier.

=cut

sub setmet {
    my $c      = shift;
    my $image_identifier  = $c->stash('image_identifier');
    my $image = Image->new(identifier => $image_identifier)->load(speculative => 1)
        or return $c->render_exception("image not found");

    my $figure = $c->param('figure') or return $c->render_exception('Error : no figure identifier');
    my $chapter = $c->param('chapter') or return $c->render_exception('Error : no chapter identifier');
    my $file = $c->req->upload('atracfile') or return $c->render_exception('Error : no actracfile');

    my $size   = $file->size;
    my $name   = $file->filename;
    my $up_dir = $c->app->config->{data_dir} . '/upload';
    -d $up_dir or mkdir $up_dir or die "couldn't mkdir $up_dir : $!";
    $up_dir .= "/$image_identifier";
    -d $up_dir or mkdir $up_dir or die "could not mkdir $up_dir : $!";

    my $temp = File::Temp->newdir( "setmet_XXXXXX", CLEANUP => 0, DIR => $up_dir );
    my $token = basename("$temp");
    $token =~ s/setmet_//;

    $file->move_to("$temp/atrac.xml") or die "failed";
    my $meta = { params => $c->req->params->to_hash };
    $meta->{timestamp} = time;
    $meta->{remote_ip} = $c->tx->remote_address;
    $meta->{dir}       = "$temp";
    $meta->{filename}  = $name;
    $meta->{filesize}  = $size;

    DumpFile("$temp/met.yaml", $meta) or die "could not write yaml";
    $c->render( name => $name, size => $size, chapter => $chapter, figure => $figure, image => $image);
}

=head2 checkmet

Check that metadata was uploaded.

=cut

sub checkmet {
    my $c = shift;
    my $image = Image->new(identifier => $c->stash('image_identifier'))->load(speculative => 1)
        or return $c->render_not_found;
    my $dir = dir(sprintf('%s/upload/%s',$c->app->config->{data_dir},$image->identifier));
    my @got;
    for my $subdir ($dir->children) {
        $subdir->is_dir or next;
        my $met = LoadFile("$subdir/met.yaml");
        my $xml = file("$subdir/atrac.xml")->slurp;
        push @got, { met => $met, xml => $xml };
    }
    $c->render(uploads => \@got);
}

=head1 show

Show metadata about an image.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('image_identifier');
    my $meta = Image->meta;
    my $object = Image->new( identifier => $identifier )
      ->load( speculative => 1, with => [qw/figure_objs/] )
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
}

=head1 list

Show images for selected report.

=cut

sub list {
    my $c = shift;
    my $identifier = $c->current_report->identifier;
    my $page = $c->page;
    my $limit = 20;
    my $offset = ( $page - 1 ) * 20;
    my $objects = Images->get_objects_from_sql(
        args => [ $identifier, $identifier ],
        sql => qq[select i.*
        from image i
            inner join image_figure_map m on m.image = i.identifier
            inner join figure f on f.identifier = m.figure
            inner join chapter c on f.chapter = c.identifier
        where c.report = ? or f.report = ?
        order by c.number,f.ordinal
        limit $limit offset $offset ]
    );
    $c->dbs->query('select count(1) from
        image i
            inner join image_figure_map m on m.image = i.identifier
            inner join figure f on f.identifier = m.figure
            inner join chapter c on f.chapter = c.identifier
        where c.report = ? or f.report = ?
        ',$identifier,$identifier)->into(my $count);
    $c->set_pages($count);
    $c->stash(objects => $objects);
    $c->SUPER::list(@_);
}

sub update_rel_form {
    my $c = shift;
    my $files = Files->get_objects(query => [ image => undef ]);
    $c->stash(relationships => [ map Image->meta->relationship($_), qw/figure_objs file/ ]);
    $c->stash(controls => {
            figure_objs => sub {
                my ($c,$obj) = @_;
                +{ template => 'figure', params => { no_thumbnails => 1 } }
              },
            file => sub {
                my ($c,$obj) = @_;
                +{ template => 'file', params => { name => 'file', values => $files } }
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

    if (my $new = $c->param('new_figure')) {
        my $img = $c->Tuba::Search::autocomplete_str_to_object($new);
        $object->add_figure_objs($img);
        $object->save(audit_user => $c->user) or do {
            $c->flash(error => $object->error);
            return $c->update_rel_form(@_);
        };
    }

    for my $id ($c->param('delete_figure')) {
        ImageFigureMaps->delete_objects({ figure => $id, image => $object->identifier });
        $c->flash(message => 'Saved changes');
    }

    # TODO remove this, just use files tab.
    my $image_dir = $c->config('image_upload_dir') or do { logger->error("no image_upload_dir configured"); die "configuration error"; };
    -d $image_dir or do { logger->error("no such dir : $image_dir"); die "configuration error"; };
    my $file = $c->req->upload('file_upload');
    if ($file && $file->size) {
        my $filename = $file->filename;
        $filename =~ s/ /_/g;
        $filename =~ tr[a-zA-Z0-9_.-][]dc;
        my $suffix;
        $filename =~ s/(\.[^.]+)$// and $suffix = $1;
        my $name = File::Temp->new(UNLINK => 0, DIR => $image_dir, TEMPLATE => $filename.'-XXXXXX', $suffix ? ( SUFFIX => $suffix ) : () );
        $file->move_to($name) or die $!;
        my $obj = File->new(file => file($name)->basename, image => $object->identifier);
        $obj->meta->error_mode('return');
        $obj->save(audit_user => $c->user) or do {
            $c->flash(error => $obj->error);
            return $c->update_rel_form(@_);
        };
    }

    if (my $id = $c->param('delete_file')) {
        my $file = File->new(identifier => $id)->load(speculative => 1) or do {
            $c->flash(error => "could not delete file $id");
            return $c->SUPER::update_rel_form(@_);
        };
        $file->image eq $object->identifier or do {
            $c->flash(error => "File $id does not belong to this image.");
            return $c->update_rel_form(@_);
        };
        $file->meta->error_mode('return');
        my $filename = "$image_dir".'/'.$file->file;
        -e $filename or die "missing file";
        $file->delete or do {
            $c->flash(error => $file->error);
            return $c->update_rel_form(@_);
        };
        unlink $filename or die $!;
        $c->flash(message => 'Saved changes');
        return $c->update_rel_form(@_);
    }
    #if (my $new = $c->param('new_file')) {
    #    $object->add_file($file);
    #    $object->save(audit_user => $c->user) or do {
    #        $c->flash(error => $object->error);
    #        return $c->render(template => 'update_rel_form');
    #    };
    #}

    #for my $id ($c->param('delete_image')) {
    #    ImageFigureMaps->delete_objects({ image => $id, figure => $object->identifier });
    #    $c->flash(message => 'Saved changes');
    #}

    $c->_redirect_to_view($object);
}

1;

