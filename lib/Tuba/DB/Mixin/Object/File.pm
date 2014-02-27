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
    $tree->{url} = get_config('asset_path').'/'.$s->file;
    $tree->{href} = $c->url_for($tree->{url})->to_abs;
    return $tree;
}

sub thumbnail_path {
    my $s = shift;
    my $thumb = $s->maybe_generate_thumbnail;
    return join '/', get_config->{asset_path},"$thumb";
}

sub maybe_generate_thumbnail {
    my $s = shift;
    if (my $existing = $s->thumbnail) {
           return $existing if -e $existing;
    }
    my $file = $s->file or return;
    my $new_thumbnail = Path::Class::File->new($file)->dir."/thumb.png";
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
    my $cmd = sprintf("convert -resize 600x600 %s[0] %s", $s->fullpath, $s->fullpath($filename));
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
    logger->info("generating thumbnail for ".$s->fullpath);
    -e $s->fullpath or do {
        logger->error("cannot find ".$s->fullpath);
        return;
    };
    my $cmd = sprintf("convert -resize 140x140 %s %s", $s->fullpath, $s->fullpath($filename));
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

1;

