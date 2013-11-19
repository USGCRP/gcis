package Tuba::DB::Object::Reference;
# Tuba::DB::Mixin::Object::Reference;
use strict;
use Pg::hstore;
use Encode qw/encode decode is_utf8/;

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
        return $v unless ref($v);
        do { $_ = encode('UTF8',$_) } for values %$v;
        my $deflated = Pg::hstore::encode($v);
        return $deflated;
    });

sub as_tree {
    my $s = shift;
    my %a = @_;
    my $c = $a{c}; # controller
    my $t = $s->SUPER::as_tree(@_, deflate => 0);
    if (my $id = $t->{publication_id}) {
      $t->{publication_uri}
        = $c ? $s->publication->to_object->uri($c) : "/publication/$id";
    }
    if (my $id = $t->{child_publication_id}) {
      $t->{child_publication_uri}
        = $c ? $s->child_publication->to_object->uri($c) : "/publication/$id";
    }
    if (my $sub = $s->subpubrefs) { # chapters
        $t->{sub_publication_uris} = [
            map {
              my $pub = $_->publication;
              $c ? $pub->to_object->uri($c) : "/publication/".$pub->id
            } @$sub
        ];
    }
    return $t;
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
    return $uuid;
}

sub attr {
    my $c = shift;
    my $k = shift;
    my $attr = $c->attrs;
    my $norm = $c->{__norm} || {};
    my %norm = %$norm;
    @norm{@{[ map lc, keys %$attr ]}} = values %$attr;
    $c->{__norm} //= \%norm;
    return $norm{$k} if $k;
    return \%norm;
}

1;

