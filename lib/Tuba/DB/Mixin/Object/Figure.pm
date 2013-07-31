package Tuba::DB::Object::Figure;
# Tuba::DB::Mixin::Object::Figure;

sub stringify {
    my $c = shift;
    return $c->title || $c->identifier;
}

sub uri {
    my $s = shift;
    my $c = shift;
    return $c->url_for(
        'show_figure',
        {
            figure_identifier => $s->identifier,
            report_identifier  => $s->report
        }
    );
}

sub numeric {
    my $c = shift;
    my $chapter = $c->chapter_obj or return "";
    return join '.', $chapter->number, $c->ordinal;
}

sub thumbnail {
    my $s = shift;
    my $c = shift;
    #die join '', map $_->name, $s->meta->relationships;
    my %seen;
    my @files = grep { !$seen{$_->file}++ } map $_->file, $s->image_objs;

    return join '', map $_->thumbnail($c, @_), @files;
}
1;

