=head1 NAME

Tuba::Activity : Controller class for books

=cut

package Tuba::Activity;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    $c->stash('object', $c->_this_object);
    $c->SUPER::show(@_);
}

sub normalize_form_parameter {
    my $c = shift;
    my %args = @_;
    my ($column, $value) = @args{qw/column value/};
    my $obj;
    for ($column) {
        /^methodology_publication_id$/ and $obj = $c->str_to_obj($value);
        /^output_publication_id$/ and $obj = $c->str_to_obj($value);
    }
    if ($obj) {
        my $pub = $obj->get_publication(autocreate => 1);
        $pub->save(audit_user => $c->user) unless $pub->id;
        return $pub->id;
    }
    return $value;
}

sub _default_order {
    my $c = shift;
    return ( $c->SUPER::_default_order(), qw/methodology_publication_id methodology_contributor_id/ );

}

sub _default_controls  {
    my $c = shift;
    return ($c->SUPER::_default_controls(@_),
        methodology_publication_id => sub {
            my $c = shift;
            { template => 'autocomplete', params => { object_type => 'all' } }
        },
        output_publication_id => sub {
            my $c = shift;
            { template => 'autocomplete', params => { object_type => 'all' } }
        },

    );
}

1;

