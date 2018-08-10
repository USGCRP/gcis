package Tuba::DB::Object::Activity;
# Tuba::DB::Mixin::Object::Activity
use Tuba::Util qw[new_uuid];
use JSON::XS;
use strict;

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid();
});

sub stringify {
    my $s = shift;
    return $s->identifier;
}

sub bounding_box {
    my $s = shift;

    my $box;
    if ( $s->spatial_extent ) {
        my $j = JSON::XS->new->decode($s->spatial_extent);
        $box = $j->{'bbox'} if $j->{'bbox'};
    }

    return $box;
};

1;

