=head1 NAME

Tuba::Controller -- base class for controllers.

=cut

package Tuba::Controller;
use Mojo::Base qw/Mojolicious::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

=head2 check, list, show

These virtual methods should be implemented by subclasses.

=cut

sub check { die "not implemented" };
sub list { die "not implemented" };
sub show { die "not implemented" };
sub create { die "not implemented" };

=head2 create_form

Create a default form.  If this is overriden by a subclass,
the template in <table>/create_form.html.ep will be used automatically,
instead of the default create_form.html.ep.

=cut

sub create_form {
    my $c = shift;
    my $class = ref $c;
    my ($object_class) = $class =~ /::(.*)$/;
    $object_class = 'Tuba::DB::Object::'.$object_class;
    $object_class->can('meta') or die "can't figure out object class for $class (not $object_class)";
    $c->stash(meta => $object_class->meta);
    $c->render(template => "create_form");
}

1;
