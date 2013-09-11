package Tuba::Importer::Processor::Findings;
use Mojo::Base qw/Tuba::Importer::Processor/;
use Tuba::DB::Objects qw/-nicknames/;
use List::MoreUtils qw/mesh/;
use Text::CSV_XS;
use Data::Dumper;

sub process {
    no warnings 'uninitialized';
    my $self = shift;
    my %args = @_;
    my $data = $args{data} or die "missing data";
    my %a = ( audit_user => $self->audit_user, audit_note => $self->audit_note );

    my $report = 'nca3draft'; # TODO allow others

    my $index = 0;
    my @labels;
    my $csv = Text::CSV_XS->new({allow_whitespace => 1});
    for my $row (@$data) {
        next unless $row;
        unless (@labels) {
            @labels = map lc, @$row;
            next;
        }
        my %record = mesh @labels, @$row;
        unless ($record{identifier}) {
            $self->_note_error("no identifier for finding", $index);
            next;
        }
        my $finding = Finding->new(identifier => $record{identifier}, report => $report);
        $finding->load(speculative => 1);
        $finding->ordinal($record{ordinal});
        $finding->statement($record{finding});
        my $pub = $record{chapter};
        if ($pub =~ m[chapter/(.*)$]) {
            $finding->chapter_identifier($1);
        }
        $finding->report($report);
        $finding->save(changes_only => 1, $self->_audit_info($index)) or do {
            $self->_note_error($finding->error, $index);
            next;
        };
        if (my $kws = $record{'gcmd science keywords'} ) {
            $csv->parse($kws) or do {
                $self->_note_error("Error parsing keywords '$kws' :" .$csv->error_diag);
                next;
            };
            for my $kw ($csv->fields) {
                 next unless $kw;
                 $kw =~ s/^\s+//;
                 $kw =~ s/\s+$//;
                 next unless $kw;
                 $kw =~ s/\s+/ /g;
                 my @fields = $kw =~ /(?:\s*)([^>]+)\s*(?: ?>|$)/g;
                 unless (@fields) {
                    $self->_note_error("Cannot parse $kw", $index); next;
                 }
                 s/^\s+// for @fields;
                 s/\s+$// for @fields;
                 my ($category, $topic, $term, $one, $two, $three) = @fields;
                 my %want = (
                  category => $category,
                  topic    => $topic,
                  term     => $term,
                  level1   => $one,
                  level2   => $two,
                  level3   => $three
                 );
                 my $k = Keyword->new(%want);
                 unless (eval { $k->load(speculative => 1); }) {
                    $self->_note_error("Failed to find keyword '$kw'", $index); next;
                 }
                 if ($@) {
                    $self->_note_error("Error loading '$kw' : $@", $index); next;
                 }
                 $finding->add_keywords($k);
                 $finding->save($self->_audit_info) or do {
                     $self->_note_error($finding->error, $index);
                 };
             }
        }
    } continue {
        $index++;
        $self->rows_processed($self->rows_processed + 1);
    }

    return $self->status('ok');
}

1;

