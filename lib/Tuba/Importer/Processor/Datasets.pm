package Tuba::Importer::Processor::Datasets;
use Mojo::Base qw/Tuba::Importer::Processor/;
use Tuba::DB::Objects qw/-nicknames/;
use List::MoreUtils qw/mesh/;
use Data::Dumper;

sub process {
    no warnings 'uninitialized';
    my $self = shift;
    my %args = @_;
    my $data = $args{data} or die "missing data";
    my %a = ( audit_user => $self->audit_user, audit_note => $self->audit_note );

    my $index = 0;
    my @labels;

    for my $row (@$data) {
        next unless $row;
        next if $row->[1] eq 'id';
        my $seq = 'XX';
        unless (@labels) {
            @labels = map { $_ = lc($_ // $seq++); tr/a-z/_/dc; $_; } @$row;
            next;
        }
        my %record = mesh @labels, @$row;
        my $id = $record{'gcmddatasetid'};
        warn join "\n", keys %record;
        if (!$id || $id =~ /need information/i) {
            $id = 'unnamed-dataset-'.$index;
        }

        my $dataset = Dataset->new(identifier => $id);
        $dataset->load(speculative => 1);
        $dataset->name($record{name});
        $dataset->version($record{version});
        $dataset->url($record{XY});
        $dataset->meta->error_mode('return');
        $dataset->save($self->_audit_info($index)) or do {
            $self->_note_error($dataset->error,$index);
            next;
        };
    } continue {
        $index++;
        $self->rows_processed($self->rows_processed + 1);
    }

    return $self->status('ok');
}

1;

