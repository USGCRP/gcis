package Tuba::DB::Object::File;
# Tuba::DB::Mixin::Object::File;
use Mojo::ByteStream qw/b/;
use Data::UUID::LibUUID;
use Path::Class ();
use Tuba::Log qw/logger/;
use Tuba::Util qw/get_config/;
use Digest::SHA1;
use Path::Class ();
use strict;

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid_string(4);
});

our %typeMap = (
        jpg => "image/jpeg",
        jpeg => "image/jpeg",
        png => "image/png",
        gif => "image/gif",
        pdf => "application/pdf",
        txt => "text/plain",
        csv => "text/csv",
);

sub supported_suffixes {
    return values %typeMap;
}

sub as_tree {
    my $s = shift;
    my %a = @_;
    my $tree = $s->SUPER::as_tree(@_);
    my $c = $a{c} or return $tree;
    $tree->{url} = $s->asset_location;
    $tree->{href} = $c->url_for($tree->{url})->to_abs;
    return $tree;
}

sub thumbnail_path {
    my $s = shift;
    my $thumb = $s->_maybe_generate_thumbnail or return '/blank.png';
    return join '/', get_config->{asset_path},"$thumb";
}

sub _maybe_generate_thumbnail {
    my $s = shift;
    if (my $existing = $s->thumbnail) {
        unless (-e $s->fullpath($existing)) {
            logger->warn("Thumbnail in db does not exist : ".$s->fullpath($existing));
            # may be on front end
        }
        return $existing;
    }
    return if $s->location; # no remote retrieval for thumbnails
    my $file = $s->file or return;
    my $file_obj = Path::Class::File->new($file);
    my $thumbnail_filename = '.thumb-'.$s->identifier.'.png';
    my $new_thumbnail = $file_obj->dir."/".$thumbnail_filename;
    if ($s->mime_type eq 'application/pdf') {
        $s->_generate_pdf_thumbnail($new_thumbnail) or return;
        $s->thumbnail($new_thumbnail);
        $s->save(audit_user => 'thumbnail') or do { logger->error($s->error); return; };
    } elsif ($s->mime_type =~ /^image/) {
        $s->_generate_image_thumbnail($new_thumbnail) or return;
        $s->thumbnail($new_thumbnail);
        $s->save(audit_user => 'thumbnail') or do { logger->error($s->error); return; };
    }
    return $s->thumbnail;
}

sub fullpath {
    my $s = shift;
    my $name = shift;
    my $base = get_config->{image_upload_dir} or die "no image_upload_dir configured";
    return join '/', $base, ($name || $s->file);
}

sub _generate_pdf_thumbnail {
    my $s = shift;
    my $filename = shift or die "missing filename";
    my $source = $s->file;
    my $dir = Path::Class::File->new($filename);
    -e $s->fullpath or do {
        logger->error("cannot open ".$s->fullpath);
        return;
    };
    my $cmd = sprintf("gm convert -resize 600x600 %s[0] %s", $s->fullpath, $s->fullpath($filename));
    system($cmd)==0 or do {
        logger->error("Command failed : $cmd : $! ${^CHILD_ERROR_NATIVE}");
        return 0;
    };
    return 1;
}

sub _generate_image_thumbnail {
    my $s = shift;
    my $filename = shift or die "missing filename";
    my $source = $s->file;
    my $dir = Path::Class::File->new($filename);
    logger->info("generating image thumbnail for ".$s->fullpath);
    die "already has one" if $s->thumbnail;
    -e $s->fullpath or do {
        logger->error("cannot find ".$s->fullpath);
        return;
    };
    my $cmd = sprintf("gm convert -resize 320x320 %s %s", $s->fullpath, $s->fullpath($filename));
    system($cmd)==0 or do {
        logger->error("Command failed : $cmd : $! ${^CHILD_ERROR_NATIVE}");
        return 0;
    };
    -e $s->fullpath($filename) or do {
        logger->error("failed to generate ".$s->fullpath($filename));
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

sub checkfix_mime_type {
    my $s = shift;
    return 1 if $s->mime_type;
    my ($suffix) = $s->file =~ /\.([^\.]+)$/;
    return unless $suffix;
    my $type = $typeMap{lc $suffix} or return;
    $s->mime_type($type);
    return 1;
}

sub set_sha1 {
    my $s = shift;
    my $d = Digest::SHA1->new;
    open my $fh, '<', $s->fullpath or do {
        logger->error("could not open ".$s->fullpath." : $! ");
        return;
    };
    $d->addfile($fh);
    my $sha1 = $d->hexdigest;
    logger->info("sha1 for ".$s->fullpath." is $sha1");
    $s->sha1($sha1);
    close $fh;
    return 1;
}

sub asset_location {
    my $s = shift;
    my $base = $s->location || get_config('asset_path');
    my $path = $s->file;
    return $base . $path;
}

1;

