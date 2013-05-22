=head1 NAME

Tuba::Image : Controller class for images.

=cut

package Tuba::Image;
use Mojo::Base qw/Mojolicious::Controller/;
use File::Temp;
use YAML::XS qw/DumpFile LoadFile/;
use Path::Class qw/file dir/;
use File::Basename qw/basename/;

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

=head1 list

List images

=cut

sub list {
    my $c = shift;
    my $images = Images->get_objects(with_objects => ['figure_obj']);
    $c->respond_to(
        json => sub { $c->render_json([ map $_->as_tree, @$images ]) },
        html => sub { $c->render(template => 'objects', meta => Image->meta, objects => $images ) }
    );
}

=head1 show

Show metadata about an image.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('image_identifier');
    my $meta = Image->meta;
    my $object =
      Image->new( identifier => $identifier )
      ->load( speculative => 1, with => [qw/figure_obj file/] )
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(report_identifier => $object->figure_obj->chapter_obj->report_obj->identifier);
    $c->respond_to(
        json => sub { shift->render(json => $object->as_tree) },
        html => sub { shift->render(template => 'object', meta => $meta, objects => $object ) }
    );
}

1;

