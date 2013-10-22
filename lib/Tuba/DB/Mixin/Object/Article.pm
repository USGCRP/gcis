package Tuba::DB::Object::Article;
# Tuba::DB::Mixin::Object::Article;

sub stringify {
    my $s = shift;
    return $s->title if $s->title;
    return $s->identifier;
}

sub uri {
    my $s = shift;
    my $c = shift;
    my $opts = shift || {};
    my $route_name = $opts->{tab} || 'show';
    return Mojo::URL->new->path("/article/".$s->identifier) if $route_name eq 'show';
    return $s->SUPER::uri($c,$opts);
}

1;

