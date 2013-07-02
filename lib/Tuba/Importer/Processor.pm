=head1 NAME

Tuba::Importer::Processor -- base class for processing imports.

=cut

package Tuba::Importer::Processor;
use Mojo::Base qw/-base/;

has 'spreadsheet';
has 'worksheet';

has rows_processed => 0;
has errors => sub { [] };
has warnings => sub { [] };

has 'audit_user';
has 'audit_note';

has 'update_only';
has 'status';

sub process {
    die "virutal method";
}

## Protected methods, used by subclasses.
sub _note_error {
    my $self = shift;
    my ($msg,$index) = @_;
    push @{ $self->errors }, { row => $index, message => $msg };
}

sub _audit_info {
    my $self = shift;
    my $index = shift;
    return ( audit_user => $self->audit_user, audit_note => $self->audit_note." row $index" ) if $index;
    return ( audit_user => $self->audit_user, audit_note => $self->audit_note);
}


1;
