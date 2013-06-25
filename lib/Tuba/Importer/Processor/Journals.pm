package Tuba::Importer::Processor::Journals;
use Mojo::Base qw/-base/;
use Tuba::DB::Objects qw/-nicknames/;
use List::MoreUtils qw/mesh/;
use Data::Dumper;

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
    no warnings 'uninitialized';
    my $self = shift;
    my %a = @_;
    my $data = $a{data} or die "missing data";

    my $index = 0;
    my @labels;
    for my $row (@$data) {
        next unless $row;
        unless (@labels) {
            @labels = map lc, @$row;
            next;
        }
        my %record = mesh @labels, @$row;
        my $journals = Journals->get_objects(query => [ title => { ilike => $record{journal_title} } ]);
        if ($journals && @$journals==1) {
            my $journal = $journals->[0];
            $journal->print_issn($record{print_issn});
            $journal->online_issn($record{online_issn});
            $journal->publisher($record{journal_pub});
            $journal->url($record{journal_url});
            $journal->meta->error_mode('return');
            $journal->save(changes_only => 1, audit_user => $self->audit_user, audit_note => $self->audit_note." row $index")
                or do {
                    push @{ $self->errors }, { row => $index, message => $journal->error };
                    };
        } else {
            push @{ $self->errors }, { row => $index, message => "no match for $record{journal_title}" };
            next;
        }
    } continue {
        $index++;
        $self->rows_processed($self->rows_processed + 1);
    }

    return $self->status('ok');
}

1;

