=head1 NAME

Tuba::Doc -- online docs for tuba

=cut

package Tuba::Doc;

use Mojo::Base qw/Tuba::Controller/;

sub examples {
    my $c = shift;
    my $sparql_url = $c->req->url->clone->to_abs;
    $sparql_url->path->parts(['sparql']);

    my $global_slr = $sparql_url->clone;
    $global_slr->path(q[/report/nca3/chapter/our-changing-climate/figure/past-and-projected-changes-in-global-slr]);

    my $sparql = [
        { desc => "List URLs for 10 figures.",
          code => 
"select * FROM <http://data.globalchange.gov>
where { ?s a gcis:Figure }
limit 10",
        },
        { desc => "List all of the findings from the Third National Climate Assessment.",
          code => 
"select * FROM <http://data.globalchange.gov>
where {
 ?s a gcis:Finding .
 ?s <http://purl.org/dc/terms/description> ?d
 }
",
        },
        {
          desc => "Find publications from which figure 2.26 (past-and-projected-changes-in-global-slr) in the NCA3 was derived.",
code =>
"select ?y FROM <http://data.globalchange.gov>
where {
 <$global_slr> gcis:hasImage ?img .
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

