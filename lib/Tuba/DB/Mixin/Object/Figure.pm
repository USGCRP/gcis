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
    my $s = shift;
    my $c = shift;
    return $c->url_for(
        'show_figure',
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

