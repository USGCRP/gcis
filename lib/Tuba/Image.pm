=head1 NAME

Tuba::Image : Controller class for images.

=cut

package Tuba::Image;
use Mojo::Base qw/Mojolicious::Controller/;
use File::Temp;
use YAML::XS qw/DumpFile/;

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

Set the metadata for this image.

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
    $file->move_to("$temp/atrac.xml") or die "failed";
    my $meta = { params => $c->req->params->to_hash };
    $meta->{timestamp} = time;
    $meta->{remote_ip} = $c->tx->remote_address;
    $meta->{dir} = "$temp";
    $meta->{filename} = $name;
    $meta->{filesize} = $size;
    DumpFile("$temp/meta.yaml", $meta) or die "could not write yaml";
    $c->render( text => "Successfully uploaded <b>$name</b> ($size bytes) ".
                        "for chapter <b>$chapter</b>, figure <b>$figure</b>, image <b>$image</b>."
              );
}

1;

