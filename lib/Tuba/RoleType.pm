=head1 NAME

Tuba::RoleType : Controller class for roles.

=cut

package Tuba::RoleType;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub _default_list_order {
    return "identifier";
}

=head1 show

Show metadata about a role.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('role_type_identifier');
    my $meta = RoleType->meta;
    my $object = RoleType->new( identifier => $identifier )
      ->load( speculative => 1 ) or return $c->reply->not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    my $stats = $c->dbs->query(<<SQL,$identifier)->hashes->[0];
select
    count(nullif(person_id is null,true)) as people,
    count(nullif(person_id is null,false)) as orgs
from contributor
where role_type_identifier = ?
SQL
    $c->stash(stats => $stats);
    $c->SUPER::show(@_);
}


1;

