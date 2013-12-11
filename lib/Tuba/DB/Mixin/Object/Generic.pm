package Tuba::DB::Object::Generic;
# Tuba::DB::Mixin::Object::Generic;
use Data::UUID::LibUUID;
use Pg::hstore;
use Encode;
use strict;

__PACKAGE__->meta->column('attrs')->add_trigger(
    inflate => sub {
        my ($o,$v) = @_;
        my $h = Pg::hstore::decode($v);
        do { $_ = decode('UTF8',$_) } for values %$h;
        return $h;
    });

__PACKAGE__->meta->column('attrs')->add_trigger(
    deflate => sub {
        my ($o,$v) = @_;
        do { utf8::downgrade($_) if defined($_) } for values %$v;
        return Pg::hstore::encode($v);
    });

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid_string(4);
});


sub new_from_reference {
    my $s = shift;  # class or instance
    my $ref = shift;
    return unless $ref->attr('reftype') =~ /^(Personal Communication)$/;

    $s = $s->new unless ref $s;
    my %new = %{ $ref->attrs };
    for (grep { /^_/ || /^\./ } keys %new) {
        delete $new{$_};
    }
    $s->attrs(\%new);
    return $s;
};

sub as_tree {
    my $s = shift;
    return $s->SUPER::as_tree(@_, deflate => 0);
}

sub type {
    return shift->attrs->{reftype};
}

1;

