package Tuba::DB::Object::Generic;
# Tuba::DB::Mixin::Object::Generic;
use Tuba::Util qw[new_uuid];
use Pg::hstore;
use Encode;
use strict;

__PACKAGE__->meta->column('attrs')->add_trigger(
    inflate => sub {
        my ($o,$v) = @_;
        return Pg::hstore::decode($v);
    });

__PACKAGE__->meta->column('attrs')->add_trigger(
    deflate => sub {
        my ($o,$v) = @_;
        return Pg::hstore::encode($v);
    });

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid();
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
    my $tree = $s->SUPER::as_tree(@_, deflate => 0);
    $tree->{description} = $s->stringify(long => 1);
    return $tree;
}


sub stringify {
    my $s = shift;
    my %args = @_;

    my $uuid = $s->identifier;
    if ($args{short}) {
        if ($uuid =~ /^(\w+)-(\w+)-(\w+)-(\w+)-(\w+)$/) {
            return $1;
        }
    }

    if($args{long}){
        my $long_name = '';
        my $type = $s->attrs->{reftype};
        if ($type)
        {
            $long_name .= $type . '. ';
        }
        my $date = $s->attrs->{Date};
        if ($date)
        {
            $long_name .= $date . '. ';
        }
        my $author = $s->attrs->{Author};
        if ($author) {
            my @list = split /\x{d}/, $author;
            $long_name .= $list[0];
            $long_name =~ s/,.*$//;
            $long_name .= ' et al.' if @list > 1;
        }
        return $long_name if length $long_name;
    }

    $title = $s->attrs->{Title};
    return $title ? $title : $uuid;
}


sub type {
    return shift->attrs->{reftype};
}

1;

