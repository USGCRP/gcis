package Tuba::DB::Object::Webpage;
# Tuba::DB::Mixin::Object::Webpage
use Data::UUID::LibUUID;
use strict;

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid_string(4);
});


sub stringify {
    my $s = shift;
    return $s->title if $s->title;
    return $s->identifier;
}

sub new_from_reference {
    my $s = shift;  # class or instance
    my $ref = shift;
    return unless $ref->attr('reftype') eq 'Web Page';

    $s = $s->new unless ref $s;

    $s->title($ref->attr('title'));
    my $url = $ref->attr('url');
    $url = "http://$url" unless $url =~ m|^http://|;
    $s->url($url);

    return $s;
};

1;

