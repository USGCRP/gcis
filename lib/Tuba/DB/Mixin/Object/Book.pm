package Tuba::DB::Object::Book;
# Tuba::DB::Mixin::Object::Book
use Data::UUID::LibUUID;
use strict;

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid_string(4);
});


sub stringify {
    my $s = shift;
    my %args = @_;
    my $str = $s->title || $s->identifier;
    return $str if $args{no_elide};
    if ($args{short}) {
        return $str unless length($str) > 30;
    }
    return substr($str,0,30).'...';
}

sub new_from_reference {
    my $s = shift;  # class or instance
    my $ref = shift;
    return unless $ref->attr('reftype') eq 'Book';

    $s = $s->new unless ref $s;

    $s->title($ref->attr('title'));
    my $url = $ref->attr('url');
    $url = "http://$url" if $url && $url !~ m|^http://|;
    $s->url($url);
    if (defined($ref->attr('isbn')) && length($ref->attr('isbn'))) {
        $s->isbn($ref->attr('isbn'));
    }
    $s->year($ref->attr('year'));
    $s->publisher($ref->attr('publisher'));
    $s->number_of_pages($ref->attr('number of pages'));

    return $s;
};

1;

