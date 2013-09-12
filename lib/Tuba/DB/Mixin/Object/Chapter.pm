package Tuba::DB::Object::Chapter;
# Tuba::DB::Mixin::Object::Chapter;

__PACKAGE__->meta->relationship('figure')->manager_args({ sort_by => "figure.ordinal" });
__PACKAGE__->meta->relationship('finding')->manager_args({ sort_by => "finding.ordinal" });

sub uri {
    my $s = shift;
    my $c = shift;
    my $opts = shift;
    my $route_name = $opts->{tab} || 'show';
    $route_name .= '_chapter';

    return $c->url_for($route_name) unless ref($s);

    return $c->url_for(
        $route_name,
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

sub sortkey {
    my $s = shift;
    return $s->{_sortkey} if defined($s->{_sortkey});
    my $num = $s->number || 0;
    $s->{_sortkey} = sprintf('%10d%s',$num,$s->title || '');
}

1;

