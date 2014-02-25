package Tuba::DB::Object::File;
# Tuba::DB::Mixin::Object::File;
use Mojo::ByteStream qw/b/;
use Data::UUID::LibUUID;
use Path::Class ();
use Tuba::Log qw/logger/;
use Tuba::Util qw/get_config/;
use Path::Class ();
use strict;

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid_string(4);
});

sub as_tree {
    my $s = shift;
    my %a = @_;
    my $tree = $s->SUPER::as_tree(@_);
    my $c = $a{c} or return $tree;
    $tree->{url} = '/img/'.$s->file;
    $tree->{href} = $c->url_for($tree->{url})->to_abs;
    return $tree;
}

sub thumbnail_path {
    my $s = shift;
    my $thumb = $s->maybe_generate_thumbnail;
    return "/img/$thumb";
    #my $filename = $s->file;
    #if ($filename =~ /(jpe?g|png)$/i) {
    #    return "/img/$filename";
    #}
    $s->generate_thumbnail;
    #die "turning $filename into $new_thumbnail";
    #return "/img/40/68/583c09961417ec23cbeef8d00222/4068583c09961417ec23cbeef8d00222.jpg"
    # <%= base %>/img/<%= $object->file %>
}

sub maybe_generate_thumbnail {
    my $s = shift;
    if (my $existing = $s->thumbnail) {
           return $existing if -e $existing;
    }
    my $file = $s->file or return;
    my $new_thumbnail = Path::Class::File->new($file)->dir."/thumb.png";
    if ($file =~ /\.pdf$/i) {
        $s->_generate_pdf_thumbnail($new_thumbnail) or return;
        $s->thumbnail($new_thumbnail);
        $s->save(audit_user => 'thumbnail') or do { logger->error($s->error); return; };
    }
    return $s->thumbnail;
}

sub _generate_pdf_thumbnail {
    my $s = shift;
    my $filename = shift or die "missing filename";
    my $source = $s->file;
    my $dir = Path::Class::File->new($filename);
    my $base = get_config->{image_upload_dir} or die "no image_upload_dir configured";
    my $cmd = "genthumb $base/$source $base/$filename";
    my $cmd = sprintf("convert -resize 600x600 %s[0] %s", "$base/$source", "$base/$filename");
    system($cmd)==0 or do {
        logger->error("Command failed : $cmd : $! ${^CHILD_ERROR_NATIVE}");
        return 0;
    };
    return 1;
}

sub basename {
    my $s = shift;
    return Path::Class::file($s->file)->basename;
}

sub stringify {
    return shift->basename;
}

1;

