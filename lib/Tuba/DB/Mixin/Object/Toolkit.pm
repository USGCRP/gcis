package Tuba::DB::Object::Toolkit;
use strict;
use Tuba::Log;

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
             uri => '/toolkit/',
             description => $self->gcid,  #overwrite description in JSON, since title is also description
                );
    my @keys_not_in_webpage = qw/relationship_identifier lexicon_identifier term context_identifier term_identifier
                                 timestamp gcid/ ;
    for my $key_not_in_webpage (@keys_not_in_webpage) {
        delete $tree{$key_not_in_webpage};
    }
    return \%tree;

}

1;
