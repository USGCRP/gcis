=head1 NAME

Tuba::Doc -- online docs for tuba

=cut

package Tuba::Doc;

use Mojo::Base qw/Tuba::Controller/;

sub examples {
    my $c = shift;
    my $sparql_url = Mojo::URL->new(q[http://data.gcis-dev-front.joss.ucar.edu/sparql]);

    my $sparql = [
        { desc => "Get a list of figures in the GCIS triplestore.",
          code => 
"select * FROM <http://data.globalchange.gov>
where { ?s a gcis:Figure }
limit 10",
        },
        { desc => "Get a list of findings in the GCIS triplestore.",
          code => 
"select * FROM <http://data.globalchange.gov>
where { ?s a gcis:Finding }
limit 10",
        },

    ];
    for (@$sparql) {
        my $url = $sparql_url->clone;
        $url->query(query => $_->{code});
        $_->{link} = $url;
    }
    $c->stash(sparql_url => $sparql_url);
    $c->stash(sparql => $sparql);
}

1;

