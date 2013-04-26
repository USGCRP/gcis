=head1 NAME

Tuba::DB  -- Rose::DB derived class for Tuba objects.

=cut

package Tuba::DB;
use Tuba::Plugin::Db;
use base 'Rose::DB';
use strict;
use warnings;

Tuba::DB->register_db(
    domain => "default",
    type => "default",
    driver => 'Pg',
);

sub dbi_connect {
    Tuba::Plugin::Db->connection->dbh;
}

1;

