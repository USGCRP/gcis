=head1 NAME

Tuba::Controller -- base class for controllers.

=cut

package Tuba::Controller;
use Mojo::Base qw/Mojolicious::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Rose::DB::Object::Util qw/unset_state_in_db/;
use List::Util qw/shuffle/;

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

sub _redirect_to_view {
    my $c = shift;
    my $object = shift;

    my $table = $object->meta->table;
    if ($object->can('identifier')) {
        return $c->redirect_to("show_$table", $table.'_identifier' => $object->identifier );
    }
    $c->app->log->warn("no identifier column cannot find view page for $object");
    return $c->render(text => "created new ".$object->table);
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
    $new->save and return $c->_redirect_to_view($new);
    $c->flash(error => $new->error);
    $c->redirect_to("create_form_$table");
}

sub _this_object {
    my $c = shift;
    my $object_class = $c->_guess_object_class;
    my $identifier = $c->stash($object_class->meta->table.'_identifier') or die "no identifier";
    my $object = $object_class->new(identifier => $identifier)->load(speculative => 1);
    return $object;
}

=head2 update_form

Generic update_form.

=cut

sub update_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);
    $c->render(template => "update_form");
}

=head2 update

Generic update for an object.

=cut

sub update {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    my %pk_changes;
    for my $col ($object->meta->columns) {
        my $param = $c->param($col->name);
        $param = undef unless defined($param) && length($param);
        my $acc = $col->accessor_method_name;
        if ($col->is_primary_key_member && $param ne $object->$acc) {
            $pk_changes{$col->name} = $param;
            next;
        }
        $object->$acc($param);
    }
    $object->meta->error_mode('return');
    my $ok = 1;
    if (keys %pk_changes) {
        # See Tuba::DB::Object.
        if (my $new = $object->update_primary_key(%pk_changes)) {
            $object = $new;
        } else {
            $ok = 0;
        }
    }
    $ok = $object->save(changes_only => 1) if $ok;
    $ok and return $c->_redirect_to_view($object);
    $c->flash(error => $object->error);
    $c->redirect_to("update_form_".$object->meta->table);
}

=head2 index

Handles / for tuba.

=cut

sub index {
    my $c = shift;
    state $count;
    unless ($count) {
        $count = Files->get_objects_count;
    }
    my $offset = int rand ($count - 50);
    $offset = 0 if $offset < 0;

    my $demo_files = Files->get_objects(
            require_objects => [qw/image_obj.figure_obj.chapter_obj/],
            offset => $offset,
            limit => 50,
        );
    my %uniq;
    for (@$demo_files) {
        $uniq{$_->file} //= $_;
    }
    $c->stash(demo_files => [ shuffle values %uniq ]);
    $c->render(template => 'index');
}
1;
