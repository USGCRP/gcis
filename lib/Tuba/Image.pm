=head1 NAME

Tuba::Image : Controller class for images.

=cut

package Tuba::Image;
use Mojo::Base qw/Mojolicious::Controller/;
use File::Temp;
use YAML::XS qw/DumpFile LoadFile/;
use File::Basename qw/basename/;

use Tuba::DB::Objects qw/-nicknames/;

=head1 ROUTES

=head2 list

Get a list of images.

=cut

=head2 met

=cut

sub met {
    my $c = shift;
    $c->respond_to(json => sub { shift->render_json({ todo => 'todo' }) }, html => sub { shift->render_text("todo")});
}

=head2 display

=cut

sub display { }

=head2 setmet

Upload metadata for this image.

=cut

sub setmet {
    my $c      = shift;
    my $figure = $c->param('figure') or return $c->render_exception('Error : no figure identifier');
    my $chapter = $c->param('chapter') or return $c->render_exception('Error : no chapter identifier');
    my $image = $c->param('image') or return $c->render_exception('Error : no image identifier');
    my $file = $c->req->upload('atracfile') or return $c->render_exception('Error : no actracfile');
    my $size   = $file->size;
    my $name   = $file->filename;
    my $up_dir = $c->app->config->{data_dir} . '/upload';
    -d $up_dir or mkdir $up_dir or die "couldn't mkdir $up_dir : $!";
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
    $c->render( token => $token, name => $name, size => $size, chapter => $chapter, figure => $figure, image => $image);
}

=head2 checkmet

Check that metadata was uploaded.

=cut

sub checkmet {
    my $c = shift;
    my $token = $c->stash('token');
    my $dir = sprintf('%s/upload/setmet_%s',$c->app->config->{data_dir},$token);
    my $met = LoadFile("$dir/met.yaml");
    my $xml = Mojo::Asset::File->new(path => "$dir/atrac.xml")->slurp;
    $c->render(met => $met, xml => $xml);
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
    my $object = Image->new(identifier => $identifier)->load(speculative => 1) or return $c->render_not_found;
    $c->respond_to(
        json => sub { shift->render(json => $object->as_tree) },
        html => sub { shift->render(template => 'object', meta => $meta, objects => $object ) }
    );
}

1;

