no warnings 'redefine';
use RDF::Trine::Parser;

sub d($) {
    Test::More::diag(shift);
}

sub import {
    no strict 'refs';
    *{[caller]->[0].'::turtle_ok'} = \&turtle_ok;
}

sub Test::Mojo::turtle_ok {
        my $t = shift;
        turtle_ok($t->tx->res->body);
        $t;
};

sub turtle_ok {
    my $ttl = shift;
    my $parser = RDF::Trine::Parser->new('turtle');
    eval {
        $parser->parse("http://test.data.globalchange.gov", $ttl, sub { 1; } );
    };

    if ($@) {
        d "Error parsing turtle :\n$@";
        d "Turtle : ";
        d $ttl;
    }
    Test::More::ok(!$@, "Parsed turtle");
}

1;
