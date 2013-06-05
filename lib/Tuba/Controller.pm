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

sub _guess_object_class {
    my $c = shift;
    my $class = ref $c;
    my ($object_class) = $class =~ /::(.*)$/;
    $object_class = 'Tuba::DB::Object::'.$object_class;
    $object_class->can('meta') or die "can't figure out object class for $class (not $object_class)";
    return $object_class;
}

=head2 create_form

Create a default form.  If this is overriden by a subclass,
the template in <table>/create_form.html.ep will be used automatically,
instead of the default create_form.html.ep.

=cut

sub create_form {
    my $c = shift;
    $c->stash(meta => $c->_guess_object_class->meta);
    $c->render(template => "create_form");
}

=head2 create

Generic create.  See above for overriding.

=cut

sub create {
    my $c = shift;
    my $class = ref $c;
    my ($object_class) = $class =~ /::(.*)$/;
    $object_class = 'Tuba::DB::Object::'.$object_class;
    my %obj;
    for my $col ($object_class->meta->columns) {
        my $got = $c->param($col->name);
        $obj{$col->name} = defined($got) && length($got) ? $got : undef;
    }
    my $new = $object_class->new(%obj);
    $new->meta->error_mode('return');
    my $table = $object_class->meta->table;
    if ($new->save) {
        if ($new->can('identifier')) {
            return $c->redirect_to("show_$table", $table.'_identifier' => $new->identifier );
        }
        # TODO look up primary key
        return $c->render(text => "created new object : ".Dumper(\%obj));
    }
    $c->flash(error => $new->error);
    $c->redirect_to("create_form_$table");
}

1;
