package Tuba::DB::Object::Figure;
# Tuba::DB::Mixin::Object::Figure;

sub stringify {
    my $c = shift;
    return $c->title || $c->identifier;
}

sub uri {
    my $s = shift;
    my $c = shift;
    return unless $s->chapter_obj;
    return $c->url_for(
        'show_figure',
        {
            figure_identifier => $s->identifier,
            report_identifier  => $s->chapter_obj->report_obj->identifier
        }
    );
}

sub numeric {
    my $c = shift;
    my $chapter = $c->chapter_obj or return "";
    return join '.', $chapter->number, $c->ordinal;
}

1;

