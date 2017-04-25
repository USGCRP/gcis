#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use tlib;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use strict;
use warnings;
use Data::Dumper;

note "This tests the API for terms of a specfic vocabulary and context, as well as the APIs for " .
     "expressing term's relationships to each other, and term mappings to GCIDs." ;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->ua->max_redirects(1); #login produces a redirect
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })
    ->status_is(200, "Login successful");
$t->ua->max_redirects(0); #reset to ignore redirects

my $base = $t->ua->server->url;  #for href check
$base =~ s[/$][];                #strip the last slash, to make tests more readable

$t->get_ok("/vocabulary/proverbs/number")
    ->status_is(200, "proverbs/number is there")
    ->or(sub {plan skip_all => "==>> This test depends on prior test!                                     <<==\n".
                     "          ==>> Make sure you have run 023_vocabulary_context.t                      <<==\n".
                     "          ==>> (Try using `--test-files 't/02*vocab*'` to run just the vocab tests) <<==\n"
             });

my $term_1_id = $t->ua->get("/uuid.json")->res->json->[0]; #->{description};
my $test_term_1 = {"lexicon_identifier" => "proverbs",
                   "context_identifier" => "number",
                   #"context_version" => "",         #version is not used, defaults to ''
                   "term" => "six",
                   #for now, at least, identifier MUST be provided, or it defaults to literal 'uuid_generate_v1()' 
                   "identifier" => $term_1_id,  
                   "is_root" => "f", 
                   "description" => "the number occurring after five and before seven",
                   "url" => "https://en.wiktionary.org/wiki/six#English",
                  };

my $test_term_1_added_fields = {
                   'cited_by' => [],
                   'term_maps' => [],
                   'parents' => [],
                   'uri' => '/vocabulary/proverbs/number/six',
                   'display_name' => 'six',
                   'is_root' => 0, #is_root put in as 'f', but comes out as 0
                   'type' => 'term',
                   'href' => $base . '/vocabulary/proverbs/number/six.json',
                   'context_version' => '',  #not used, but returned
                   'children' => [],
                  };

$t->ua->max_redirects(1); #post produces a redirect
$t->post_ok("/vocabulary/proverbs/number" => json => $test_term_1)
    ->status_is(200, "Add number 'six'"); #this doesn't test anything - status is 200 even if db error
                                          #better to test Location of redirect goes to /vocabulary/proverbs/number/six
$t->ua->max_redirects(0);

#my $term_1_identifier = $t->ua->get("/vocabulary/proverbs/number/six.json")->res->json->{identifier}; #->{description};
#diag("six identifier is $term_1_id");
#diag("JSON is " .  $term_1_identifier);

#There is no good reason why I switch between single quotes, double quotes, and implied quotes 
#in the sections below.  They all work.

$t->get_ok("/vocabulary/proverbs/number/six.json")
    ->status_is(200, "number 'six' exists")
    ->json_is('', {%$test_term_1,
                   %$test_term_1_added_fields,
                  }, "six json check");

my $term_2_id = $t->ua->get("/uuid.json")->res->json->[0]; 
my $test_term_2 = {"lexicon_identifier" => "proverbs",
                   "context_identifier" => "number",
                   #"context_version" => "",         #version is not used, defaults to ''
                   "term" => "half a dozen",
                   "identifier" => $term_2_id,
                   "is_root" => "f", 
                   "description" => "divide a dozen in half",
                   "url" => "https://en.wiktionary.org/wiki/half_a_dozen"};

my $test_term_2_added_fields = {
                   'children' => [],
                   'cited_by' => [],
                   'context_version' => '',    #not used, but returned      
                   'display_name' => 'half a dozen',
                   'href' => $base . '/vocabulary/proverbs/number/half%20a%20dozen.json',
                   'is_root' => 0,             #is_root put in as 'f', but comes out as 0
                   'parents' => [],
                   'term_maps' => [],
                   'type' => 'term',
                   'uri' => '/vocabulary/proverbs/number/half%20a%20dozen',
                };

#based off of 'location_is' example custom test in 'perldoc Mojo::Test'
      my $location_unlike = sub {
        my ($t, $value, $desc) = @_;
        $desc ||= "Location unlike: $value";
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        return $t->success(unlike($t->tx->res->headers->location, $value, $desc));
      };


$t->post_ok("/vocabulary/proverbs/number" => json => $test_term_2)
    ->status_is(302, "Add number 'half a dozen'")
    ->$location_unlike(qr'/form/create', '"half a dozen" insert successful'); 

#Now, associate the two terms using a term_relationship
my $term_1_2_rel = {term_subject => $term_1_id,                   #'cheating', since I know the identifier
                    relationship_identifier => 'owl:sameAs',          #this is preloaded via base_data.sql
                    term_object => $t->ua->get("/vocabulary/proverbs/number/half a dozen.json")
                                                 ->res->json->{identifier} #way to get id if you don't know it
                   };
###############################
# On using HTML vs JSON tests #
###############################
# Either of the 2 post_ok statements below can be used, keeping both here, with one commented out
# for examples of how to test for failure of each method.
# For either method, a truly successful post (DB insert) should pass all checks as they are written.
# If you want to experiment with failures, give a bogus value to one of the three hash values above.

#$t->post_ok("/term_relationship" => json => $term_1_2_rel)        #POST as HTML
$t->post_ok("/term_relationship.json" => json => $term_1_2_rel)    #POST as JSON
    ->status_is(302, "Add relationship 'six' 'owl:sameAs' 'half_a_dozen'")   #valid ONLY for .json
    ->or(sub { diag "Response body is:"; diag explain $t->tx->res->body })   #only if status != 302
    #->$location_unlike(qr'/term')
    ->$location_unlike(qr'create','HTML Insert successful')                  #valid ONLY for HTML 
                                                       #a failed html post redirects to create_form_term_relationship
                                                       #(a failed json post has location=>undef)
    ->or(sub { diag "This means the HTML post to add the row actually failed" })
    ->json_is('/error' => undef, 'Check for JSON errors');                   #valid ONLY for .json

##############################

my $test_term_2_rel_fields = {         #half_a_dozen
                      'parents' => [
                          {
                              'relationship' => 'owl:sameAs',
                              'subject' => '/vocabulary/proverbs/number/six',
                          }
                      ]
                  };

my $test_term_1_rel_fields = {         #six
                        'children' => [
                            {                       
                                'object' => '/vocabulary/proverbs/number/half%20a%20dozen',
                                'object_tree' => {
                                    %$test_term_2,
                                    %$test_term_2_added_fields,
                                    %$test_term_2_rel_fields,   #replaces empty parents array
                                },
                                'relationship' => 'owl:sameAs',
                            }
                        ]
                    };


$t->get_ok("/vocabulary/proverbs/number/six.json#Relationship_test")
    ->json_is('', {%$test_term_1,
                   %$test_term_1_added_fields,
                   %$test_term_1_rel_fields,     #replaces empty children array
                  }, "six json check with children");

$t->get_ok("/vocabulary/proverbs/number/half a dozen.json#Relationship_test")
    ->json_is('', {%$test_term_2,
                   %$test_term_2_added_fields,
                   %$test_term_2_rel_fields,     #replaces empty parents array
                  }, "'half a dozen' json check with parents");

$t->delete_ok("/term_relationship/$term_1_id/owl:sameAs/$term_2_id");   

$t->get_ok("/vocabulary/proverbs/number/six.json#Relationship_deleted_test")
    ->json_is('', {%$test_term_1,
                   %$test_term_1_added_fields,
                  }, "six json check with children deleted");

$t->get_ok("/vocabulary/proverbs/number/half a dozen.json#Relationship_deleted_test")
    ->json_is('', {%$test_term_2,
                   %$test_term_2_added_fields,
                  }, "'half a dozen' json check with parents deleted");

$t->post_ok("/relationship.json" => json => {identifier => 'test:hasToolkit',
                                             description => 'For a CRT Toolkit'} )
    ->status_is(302, "Add relationship for hasToolkit")
    ->or(sub { diag "Response body is:"; diag explain $t->tx->res->body }) ;

my $gcid_target ="http://toolkit.climate.gov/tool/maca-cmip5-statistically-downscaled-climate-projections"; 

my $term_1_term_map = {term_identifier => $term_1_id,
                    relationship_identifier => 'test:hasToolkit',
                    gcid => $gcid_target, 
                    description => "CMIP5 output is downscaled from native resolutions to either 4-km or " .
                                   "6-km using the MACA method"
                   };

$t->post_ok("/term_map.json" => json => $term_1_term_map)
    ->status_is(302, "Add term_map for 'six'")
    ->or(sub { diag "Response body is:"; diag explain $t->tx->res->body })
    ->json_is('/error' => undef, 'Check for term_map post JSON errors');

$t->get_ok("/vocabulary/proverbs/number/six.json#term_map_test")
    ->json_is('', {%$test_term_1,
                   %$test_term_1_added_fields,
                   term_maps => [             #replaces empty term_maps array
                       {
                           object => $gcid_target,
                           relationship => 'test:hasToolkit',
                       }
                   ],
                  }, "six json check with term_map");

$t->delete_ok("/term_map/$term_1_id/test:hasToolkit/$gcid_target");

$t->get_ok("/vocabulary/proverbs/number/six.json#term_map_test")
    ->json_is('', {%$test_term_1,
                   %$test_term_1_added_fields,
                  }, "six json check with term_map deleted");

=comment Handy statements to dump out the JSON of the things used here

diag("Six has json:\n"); diag  explain($t->ua->get("/vocabulary/proverbs/number/six.json")
                                                 ->res->json);
diag("Half a dozen has json:\n"); diag explain($t->ua->get("/vocabulary/proverbs/number/half a dozen.json")
                                                 ->res->json);
diag("relationship has json:\n" . Dumper($t->ua->get("/relationship.json")
                                                 ->res->json));

=cut

done_testing();

1;

