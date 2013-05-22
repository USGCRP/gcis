package Tuba::DB::Object;

use strict;
use warnings;

# Override these in mixin classes, e.g. Tuba::DB::Mixin::Object::Chapter
sub stringify {
    my $s = shift;
    my $pk = $s->meta->primary_key;
    return $s->meta->table.' : '.$s->$pk;
}

sub uri {
    my $s = shift;
    my $c = shift;
    my $pk = $s->meta->primary_key;
    return $c->url_for( 'show_'.$s->meta->table, { $s->meta->table.'_'.$pk => $s->$pk } );
}

1;

