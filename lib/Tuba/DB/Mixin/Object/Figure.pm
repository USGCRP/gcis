package Tuba::DB::Object::Figure;
# Tuba::DB::Mixin::Object::Figure;

sub stringify {
    my $c = shift;
    if (my $num = $c->numeric) {
        return join ' ', $num, ($c->title || $c->identifier);
    }
    return $c->title || $c->identifier;
}

sub uri {
    my $s          = shift;
    my $c          = shift;
    my $opts       = shift;
    my $route_name = $opts->{tab} || 'show';
    $route_name .= '_figure';

    return $c->url_for( $route_name ) unless ref $s;

    return $c->url_for(
        $route_name,
        {
            figure_identifier => $s->identifier,
            report_identifier  => $s->report_identifier,
        }
    );
}

sub numeric {
    my $c = shift;
    my $chapter = $c->chapter or return "";
    return join '.', $chapter->number, $c->ordinal;
}

1;

