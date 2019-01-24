=head1 NAME

Tuba::ReportType : Controller class for report types.

=cut

package Tuba::ReportType;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub _default_list_order {
    return "identifier";
}

=head1 show

Show metadata about a report types.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('report_type_identifier');
    my $meta = ReportType->meta;
    my $object = ReportType->new( identifier => $identifier )
      ->load( speculative => 1 ) or return $c->reply->not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
}



1;

