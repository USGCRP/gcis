package Tuba::DB::Object::GcmdKeyword;
use Tuba::Log;
use Data::Dumper;
# Tuba::DB::Mixin::Object::GcmdKeyword;

sub stringify {
    my $self = shift;
    my %args = @_;
    if ($args{short}) {
        return $self->label;
    }
    if (my $parent = $self->parent) {
        return join '>', $self->parent->label, $self->label;
    }
    return $self->label;
}

sub new_from_flat {
    my $c = shift;
    my %h = @_;
    # Example :
    #    {
    #        'id' => '5286',
    #        'category' => 'EARTH SCIENCE',
    #        'topic' => 'HUMAN DIMENSIONS',
    #        'term' => 'ENVIRONMENTAL IMPACTS',
    #        'level1' => 'FOSSIL FUEL BURNING'
    #        'level2' => undef,
    #        'level3' => undef,
    #    };
    my $new;
    my @cols = qw/category topic term level1 level2 level3/;
    my %cols;
    @cols{@cols} = @h{@cols};
    my $ds = DBIx::Simple->new(Tuba::Plugin::Db->connection->dbh);
    my @rows = $ds->select('vw_gcmd_keyword', '*', \%cols )->hashes;
    return unless @rows > 0;
    unless (@rows==1) {
        logger()->warn("we got ".@rows." rows for ".dumpit(\%h));
    }
    my $identifier = $rows[0]->{identifier};
    return $c->new(identifier => $identifier);
}

1;

