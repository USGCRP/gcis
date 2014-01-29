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
    my $org = Tuba::DB::Object::Organization->find_or_make(
      name  => ( $ref->attr('institution') || $ref->attr('publisher') ),
      audit => {audit_user => 'unknown'}
    );
    $s->organization_identifier($org->identifier);

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

1;

