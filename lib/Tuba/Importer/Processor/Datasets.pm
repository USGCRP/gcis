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
        unless (@labels) {
            @labels = map { $_ = lc($_ // 'x'); tr/a-z/_/dc; $_; } @$row;
            next;
        }
        my %record = mesh @labels, @$row;
        my $seq = 'A';
        for (@$row[1..$#$row]) {
            $record{$seq++} = $_;
        }

        my $id = $record{'gcmddatasetid'};
        if (!$id || $id =~ /need information/i) {
            $id = 'unnamed-dataset-'.$index;
        }

        $id =~ s/^\s+//;
        $id =~ s/\s+$//;

        my $dataset = Dataset->new(identifier => $id);
        $dataset->load(speculative => 1);
        $dataset->name($record{E});
        $dataset->version($record{version});
        $dataset->url($record{K});
        $dataset->meta->error_mode('return');
        $dataset->save($self->_audit_info($index)) or do {
            $self->_note_error($dataset->error,$index);
            next;
        };
        if (my $creator = $record{I}) {
            my $match = Organizations->get_objects(query => [ identifier => { ilike => $creator } ]);
            if ($match && @$match==1) {
                my $organization = $match->[0]->identifier;
                my $new = DatasetOrganizationMap->new(organization => $organization, dataset => $id);
                unless ($new->load(speculative => 1)) {
                    $new->save($self->_audit_info($index));
                }
            } else {
                $self->_note_warning("Could not match organization $creator", $index);
            }
        }
        if (my $figures = $record{B}) {
            for my $figure (split /\s*,\s*/, $figures) {
                $figure =~ s[/figure/][];
                my $fig = Figure->new(identifier => $figure);
                $fig->load(speculative => 1) or do {
                    $self->_note_error("could not load figure $figure", $index);
                    next;
                };
                my $dataset_publication = $dataset->get_publication(autocreate => 1);
                $dataset_publication->save($self->_audit_info($index));
                my $figure_publication = $fig->get_publication(autocreate => 1);
                $figure_publication->parent_id($dataset_publication->id);
                $figure_publication->parent_rel('prov:wasDerivedFrom');
                $figure_publication->save($self->_audit_info($index));
            }
        }
        if (my $images = $record{C}) {
            for my $image (split /\s*,\s*/, $images) {
                $image =~ s[/image/][];
                my $img = Image->new(identifier => $image);
                $img->load(speculative => 1) or do {
                    $self->_note_error("could not load image $image", $index);
                    next;
                };
                my $dataset_publication = $dataset->get_publication(autocreate => 1);
                $dataset_publication->save($self->_audit_info($index));
                my $image_publication = $img->get_publication(autocreate => 1) or die "could not make publication for image";
                $image_publication->parent_id($dataset_publication->id);
                $image_publication->parent_rel('prov:wasDerivedFrom');
                $image_publication->save($self->_audit_info($index));
            }
        }
    } continue {
        $index++;
        $self->rows_processed($self->rows_processed + 1);
    }

    return $self->status('ok');
}

1;

