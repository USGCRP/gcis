package Tuba::DB::Object::Report;
# Tuba::DB::Mixin::Object::Report
use Rose::DB::Object::Util qw/:all/;

use Tuba::Log;

sub new_from_reference {
    my $s = shift;
    my $ref = shift;
    return unless $ref->attr('reftype') =~ /^(Report|Government Document)$/;
    $s = $s->new unless ref $s;
    my $title = $ref->attr("title");

    $s->url($ref->attr('url'));
    $s->load(speculative => 1) if $s->url && !is_in_db($s);

    $s->doi($ref->attr('doi'));
    $s->load(speculative => 1) if $s->doi && !is_in_db($s);

    unless ($s->identifier) {
        $s->identifier($s->make_identifier(name => $title, abbrev => 1, min_length => 5));
        $s->load(speculative => 1);
    }

    $s->title($title);
    $s->publication_year($ref->attr('year'));
    return $s;
}

sub organizations {
    my $s = shift;
    my $pub = $s->get_publication or return;
    my $orgs = Tuba::DB::Object::Organization::Manager->get_objects(
        query => [ publication_id => $pub->id, person_id => undef ],
        with_objects => [ qw/contributors.publications/ ] );
    return @$orgs;
}

sub as_text {
    my $s = shift;
    # TODO authors, year : title <url>
    my $cons = "";
    if (my $pub = $s->get_publication) {
        my @contributors = $pub->contributors_having_role('author');
        $cons = join ',', map $_->as_text, @contributors;
    }
    return sprintf('%s %04d: %s, <%s>',
        $cons,
        $s->publication_year,
        $s->title,
        $s->doi ? 'doi : '.$s->doi : $s->url,
    );
}

sub reference_count {
    my $ch = shift;
    my $pub = $ch->get_publication or return 0;
    # chapter, figures, findings, tables are in subpubref, but reports are not.
    # So this is overloaded in mixin/report.pm
    my $sql = q[select count(1) from subpubref where publication_id = ?];
    my $dbs = DBIx::Simple->new($ch->db->dbh);
    my ($count) = $dbs->query($sql, $pub->id)->flat;
    return $count;
}

sub count_figures {
    my $s = shift;
    return Tuba::DB::Object::Figure::Manager->get_objects_count({ report_identifier => $s->identifier});
}

sub count_findings {
    my $s = shift;
    return Tuba::DB::Object::Finding::Manager->get_objects_count({report_identifier => $s->identifier});
}

sub count_tables {
    my $s = shift;
    return Tuba::DB::Object::Table::Manager->get_objects_count({report_identifier => $s->identifier});
}

sub count_chapters {
    my $s = shift;
    return Tuba::DB::Object::Chapter::Manager->get_objects_count({report_identifier => $s->identifier });
}

sub count_images {
    my $s = shift;
    return Tuba::DB::Object::Image::Manager->get_objects_count(
            query => [ report_identifier => $s->identifier ],
            with_objects => [qw/figures/]
    );
}

sub images {
    my $s = shift;
    return Tuba::DB::Object::Image::Manager->get_objects(
            query => [ report_identifier => $s->identifier ],
            with_objects => [qw/figures/]
    );
}

sub stringify {
    my $s = shift;
    my %args = @_;
    return $s->identifier if $args{short} || $args{tiny};
    my $str = $s->title || $s->identifier;
    return $str;
}

1;

