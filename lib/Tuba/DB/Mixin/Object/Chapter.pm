package Tuba::DB::Object::Chapter;
# Tuba::DB::Mixin::Object::Chapter;

__PACKAGE__->meta->relationship('figures')->manager_args({ sort_by => "figure.ordinal" });
__PACKAGE__->meta->relationship('findings')->manager_args({ sort_by => "finding.ordinal" });
__PACKAGE__->meta->relationship('tables')->manager_args({ sort_by => "table.ordinal" });

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
    my $str = ' ('.$s->report_identifier.')';
    return $s->identifier.$str unless $s->title || $s->number;
    return $s->title.$str unless $s->number;
    return "Chapter ".$s->number." : ".($s->title || '').$str;
}

sub sortkey {
    my $s = shift;
    return $s->{_sortkey} if defined($s->{_sortkey});
    my $num = $s->number || 0;
    $s->{_sortkey} = sprintf('%10d%s',$num,$s->title || '');
}

1;

