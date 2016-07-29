package Tuba::DB::Object::CaseStudy;
use strict;

sub stringify {
    my $self = shift;
    return $self->description;
}

sub as_tree {
    my $self = shift;
    my $id = $self->gcid;
    my $id =~ s!.*//!!;
    my $default_tree = $self->SUPER::as_tree;
    my %tree = (
             %$default_tree,
             url => $self->gcid,
             identifier => $id,
             title => $self->stringify,
             access_date => $self->timestamp,
             uri => '/case_study/',
                );
    my @keys_not_in_webpage = qw/relationship_identifier lexicon_identifier term context_identifier term_identifier
                                 timestamp gcid/ ;
    for my $key_not_in_webpage (@keys_not_in_webpage) {
        delete $tree{$key_not_in_webpage};
    }
    return \%tree;
}

1;
