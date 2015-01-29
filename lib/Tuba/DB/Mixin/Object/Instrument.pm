package Tuba::DB::Object::Instrument;
# Tuba::DB::Mixin::Object::Instrument;
use strict;

sub count_datasets {
    my $s = shift;
    my %args = @_;
    my $platform = $args{platform} or die "missing platform";

    my $dbh = $s->db->dbh;
    my $sth = $dbh->prepare(<<'SQL');
select count(1) as c
from instrument_measurement
    where platform_identifier = ? and instrument_identifier = ?
SQL
    $sth->execute($platform->identifier,$s->identifier) or die $dbh->errstr;
    my $rows = $sth->fetchall_arrayref({});
    return $rows->[0]->{c};
}

1;

