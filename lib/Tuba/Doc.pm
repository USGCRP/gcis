=head1 NAME

Tuba::Doc -- online docs for tuba

=cut

package Tuba::Doc;

use Mojo::Base qw/Tuba::Controller/;

sub examples {
    my $c = shift;
    my $sparql_url = Mojo::URL->new(q[http://data.gcis-dev-front.joss.ucar.edu/sparql]);
    my $base = "http://data.gcis-dev-front.joss.ucar.edu";

    my $sparql = [
        { desc => "List URLs for 10 figures.",
          code => 
"select * FROM <http://data.globalchange.gov>
where { ?s a gcis:Figure }
limit 10",
        },
        { desc => "List all of the findings from the NCA3 draft report.",
          code => 
"select * FROM <http://data.globalchange.gov>
where {
 ?s a gcis:Finding .
 ?s <http://purl.org/dc/terms/description> ?d
 }
",
        },
        {
          desc => "Find publications from which figure 2.26 (global-slr) in the draft nca3 was derived.",
code =>
"select ?y FROM <http://data.globalchange.gov>
where {
 <$base/report/nca3draft/chapter/our-changing-climate/figure/global-slr> gcis:hasImage ?img .
 ?img prov:wasDerivedFrom ?y
}
limit 10"
}
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

