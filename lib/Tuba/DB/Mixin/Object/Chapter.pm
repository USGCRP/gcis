package Tuba::DB::Object::Chapter;
# Tuba::DB::Mixin::Object::Chapter;

__PACKAGE__->meta->relationship('figure')->manager_args({ sort_by => "figure.ordinal" });

sub uri {
    my $s = shift;
    my $c = shift;
    return $c->url_for(
        'show_chapter',
        {
            chapter_identifier => $s->identifier,
            report_identifier  => $s->report->identifier
        }
    );
}

sub stringify {
    my $s = shift;
    return $s->title unless $s->number;
    return "Chapter ".$s->number." : ".$s->title;
}

1;

