package Tuba::DB::Object::Article;
# Tuba::DB::Mixin::Object::Article;
use Rose::DB::Object::Util qw/:all/;
use Tuba::Log;
use strict;

sub stringify {
    my $s = shift;
    return $s->title if $s->title;
    return $s->identifier;
}

sub uri {
    my $s = shift;
    my $c = shift;
    my $opts = shift || {};
    my $route_name = $opts->{tab} || 'show';
    if ($route_name eq 'show') {
        my $uri = Mojo::URL->new->path("/article/".$s->identifier);
        $uri->base($c->req->url->base) if $c;
        return $uri;
    }
    return $s->SUPER::uri($c,$opts);
}

sub new_from_reference {
    my $s = shift;
    my $ref = shift;
    return unless $ref->attr('reftype') eq 'Journal Article';

    $s = $s->new unless ref $s;

    my $doi = $ref->attr('doi');
    $s->doi($doi);
    if ($doi) {
        $s->load(speculative => 1);
        $s->identifier($doi) unless $s->identifier;
    } elsif (!$s->identifier) {
        my $title = $ref->attr('title');
        $title =~ tr/a-zA-Z0-9 //dc;
        $title =~ s/ /-/g;
        $title = lc $title;
        $s->identifier('missing_doi_'.$title);
    }
    $s->title($ref->attr('title'));
    $s->year($ref->attr('year'));
    $s->url($ref->attr('url'));
    $s->journal_pages($ref->attr('journal_pages'));
    $s->journal_vol($ref->attr('journal_vol'));

    my $journal_identifier;
    my $issns = $ref->attr('issn') || '';

    my $journal;
    while ($issns =~ /(\w{4}-\w{4})/g) {
        my $issn = $1;
        $journal = Tuba::DB::Object::Journal->new(print_issn => $issn);
        $journal->load(speculative => 1) and last;
        $journal = Tuba::DB::Object::Journal->new(online_issn => $issn);
        $journal->load(speculative => 1) and last;
        undef $journal;
    }
    unless ($journal) {
        $journal = Tuba::DB::Object::Journal->new;
        my @issns = ( $issns =~ /(\w{4}-\w{4})/ );
        $journal->print_issn($issns[0]) if @issns;
        $journal->title($ref->attr('journal'));
        my $identifier = $ref->attr('journal');
        $identifier =~ tr/a-zA-Z 0-9-//cd;
        $identifier = lc $identifier;
        $identifier =~ s/ /-/g;
        $journal->identifier($identifier);
        $journal->load(speculative => 1) or do {
            logger->warn("making a new journal, identifier : $identifier");
            $journal->save(audit_user => 'unknown');
        };
    }
    $s->journal_identifier($journal->identifier);

    return $s;
}

1;

