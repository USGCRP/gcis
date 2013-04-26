=head1 NAME

Tuba::Plugin::Debug - helpful diagnostics

=head1 DESCRIPTION

This plugin is if the server is in debug mode; it provides
extra routes to aid in debugging.
 
=cut

package Tuba::Plugin::Debug;
use Mojo::Base qw/Mojolicious::Plugin/;
use Data::Dumper;

sub _render_debug {
    my $c = shift;

    die "no database handle\n\n$DBI::errstr\n" unless $c->db->dbh;
    my @output;

    my $got = $c->db->dbh->selectall_arrayref('select 42') or die $DBI::errstr;
    push @output, "db said @{$got->[0]}";

    my ($flat) = $c->dbs->query('select 42')->flat;
    push @output, "db said $flat";

    my $orm = $c->orm;
    for my $table (sort keys %$orm) {
        push @output, "$table : ".join ' ', $orm->{$table}{obj}->meta->columns;
    }

    $c->res->headers->content_type('text/plain');
    $c->render_text(join "\n", @output);
}

sub register {
    my ($self, $app, $conf) = @_;
    return if $app->mode eq 'production';
    return unless $ENV{TUBA_DEBUG};

    $app->routes->get('/debug' => \&_render_debug);

    1;
}

1;

