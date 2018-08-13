=head1 NAME

Tuba::Generic : Controller class for generic publications.

Generic publications just have an hstore and a uuid; they can
have arbitrary key-value pairs associated with them.

=cut

package Tuba::Generic;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $meta = Generic->meta;
    my $identifier = $c->stash('generic_identifier');
    my $object =
      Generic->new( identifier => $identifier )->load( speculative => 1)
      or return $c->reply->not_found;
    $c->stash(object => $object);
    $c->SUPER::show(@_);
}

sub list {
    my $c = shift;
    $c->stash(extra_cols => ['type']);
    $c->SUPER::list(@_);
}

sub update {
    my $c = shift;
    $c->SUPER::update(@_) if (my $json = $c->req->json);

    my $generic = $c->_this_object or return $c->reply->not_found;

    if (my $params = $c->req->params->to_hash ) {
        if ( $params->{delete_pub_attr} ) {
            $generic->delete_attr( { del_attr => $params->{delete_pub_attr}, audit_user => $c->user, audit_note => "Deleting attributes" });
            $c->redirect_without_error('update_form');
        }
        # find any new attr keys or attribute_* keys
        elsif ( exists $params->{new_attr_key} || grep { /^attribute/ } keys %$params ) {
            my $new_attributes = _collect_attributes($params);
            $generic->set_attr( { new_attrs => $new_attributes, audit_user => $c->user, audit_note => "Setting attributes" });
            $c->redirect_without_error('update_form');
        }
        else {
            $c->SUPER::update(@_);
        }
    }
}

sub _collect_attributes {
    my ( $params ) = @_;
    my $attrs;

    # any newly entered key should overwrite existing of that name.
    my $new_attr_flag = 0;
    foreach my $key ( keys %$params ) {
        next if $key eq 'new_attr_value';
        if ( $key eq 'new_attr_key') {
            $new_attr_flag = 1;
        }
        if ( $key =~ /^attribute_(.*)/ && $params->{ $key } ) {
            $attrs->{"$1"} = $params->{$key};
        }
    }
    if ( $new_attr_flag ) {
        $attrs->{ $params->{'new_attr_key'} } = $params->{'new_attr_value'}
    }

    return $attrs;
}



1;

