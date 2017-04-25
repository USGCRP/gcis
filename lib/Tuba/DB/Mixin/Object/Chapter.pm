package Tuba::DB::Object::Chapter;
# Tuba::DB::Mixin::Object::Chapter;

use Tuba::Log;

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
            report_identifier  => $s->report_identifier
        }
    );
}

sub stringify {
    my $s = shift;
    my %args = @_;
    return ($s->number // $s->identifier) if $args{tiny};
    my $str = $s->report_identifier;
    if ($args{display_name}) {
        my ($maybe_prepend_report, $maybe_append_report) = ('','');
        unless ($args{short}) {       #'short' used esp. for listing chapters of a given report
            if (length($str) <= 16) { #eg, 'usgcrp-ocpfy2015' This is short enough to look nice.
                $maybe_prepend_report = uc($str);
            } else {
                my $report_title = $s->report->title;
                $maybe_append_report = " (in '$report_title')";
            }
        }
        my $chap_str;
        if (!($s->title || $s->number)) {
            $chap_str = ($maybe_prepend_report ? ' ' : '' ) . 'Chapter: ' . $s->identifier;
            #This will probably be ugly, so throw warning
            logger->warn("Report_identifer $str, Chapter identifier " . $s->identifer .
                         "has NO title or number!");
        } elsif (!$s->number) {
            $chap_str = ($maybe_prepend_report ? ': ' : '') . $s->title;
        } else {
            $chap_str = ($maybe_prepend_report ? ' ' : '') . 'Chapter ' . $s->number
                        . ($s->title ? ': '.$s->title : '');
        }
        return $maybe_prepend_report . $chap_str . $maybe_append_report;
    }
    #below is old behavior (ie, no 'display_name' (or 'tiny') args)
    return $str.' chapter : '.$s->identifier unless $s->title || $s->number;
    return $str.' '.$s->title unless $s->number;
    return "$str chapter ".$s->number." : ".($s->title || '');
}

sub sortkey {
    my $s = shift;
    return $s->{_sortkey} if defined($s->{_sortkey});
    my $num = $s->number || 0;
    $s->{_sortkey} = sprintf('%10d%s',$num,$s->title || '');
}

sub count_figures {
    my $s = shift;
    return Tuba::DB::Object::Figure::Manager->get_objects_count({ report_identifier => $s->report_identifier, chapter_identifier => $s->identifier });
}

sub count_findings {
    my $s = shift;
    return Tuba::DB::Object::Finding::Manager->get_objects_count({report_identifier => $s->report_identifier,  chapter_identifier => $s->identifier });
}

sub count_tables {
    my $s = shift;
    return Tuba::DB::Object::Table::Manager->get_objects_count({report_identifier => $s->report_identifier,  chapter_identifier => $s->identifier });
}

1;

