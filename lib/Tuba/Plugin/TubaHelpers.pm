=head1 NAME

Tuba::Plugin::TubaHelpers -- various helpers

=head1 SYNOPSIS

app->plugin( 'tuba_helpers')

=cut

package Tuba::Plugin::TubaHelpers;
use Mojo::Base qw/Mojolicious::Plugin/;
use Time::Duration qw/ago/;
use List::Util qw/min/;
use Date::Parse qw/str2time/;
use DateTime::Format::Human::Duration;
use Number::Format;
use Number::Bytes::Human qw/format_bytes/;
use Mojo::ByteStream qw/b/;
use Mojo::Util qw/decamelize xml_escape/;
use URI::Find;
use Lingua::EN::Inflect qw/A PL PL_V/;
use Sort::Key qw/keysort/;

use Tuba::Log;
use Tuba::DocManager;

#
# Usage :
#   include_first [ 'foo/bar', 'bar' ] => ...
#
sub _include_first {
  my $c    = shift;
  my $list = shift;
  for my $item (@$list) {
    my $got = $c->render_to_string($item, @_);
    return $got if $got;
  }
  return "";
}

#
# Usage _look_similar($a,$b)
# Do $a and $b look similar?
#
sub _look_similar {
    my ($x,$y) = @_;
    $x //= '';
    $y //= '';
    s/^\s+// for ($x,$y);
    s/\s+$// for ($x,$y);
    return $x eq $y;
}

sub register {
    my ($self, $app, $conf) = @_;

    my $supported_formats = $conf->{supported_formats};

    $app->helper(base => sub {
        my $c = shift;
        my $base = $c->url_for('index')->path;
        $base =~ s[/$][];
        return $base;
    } );
    $app->helper(obj_link => sub {
            my $c = shift;
            my $obj = shift;
            return "" unless defined($obj);
            return "$obj" if ref($obj) eq 'DateTime';
            my $val = $obj->stringify(@_) || '[missing '.$obj->moniker.']';
            my $uri = $obj->uri($c);
            return $val unless $uri;
            return $c->link_to($val, $uri, @_ );
        } );
    $app->helper(obj_link_to => sub {
            my $c = shift;
            my $obj = shift;
            my $tab = shift;
            my $uri = $obj->uri($c,{ tab => $tab });
            return $c->link_to($uri, @_ );
        });
    $app->helper(obj_uri_for => sub {
            my $c = shift;
            my $obj = shift or return "";
            my $tab = shift;
            return $obj->uri($c,{ tab => $tab });
        });

    $app->helper(format_ago => sub {
            my $c = shift;
            my $date = shift;
            return ago(time - str2time($date), 1);
        });
    $app->helper(current_resource => sub {
            my $c = shift;
            if (my $cached = $c->stash('_current_resource')) {
                return $cached;
            }
            my $str = $c->req->url->clone->to_abs;
            for my $format (@$supported_formats) {
                $str =~ s/\.$format$// and last;
                $str =~ s/\.$format\?show_all.*$// and last;
            }
            $c->stash('_current_resource' => $str);
            $str;
        });
    $app->helper(rdf_resource => sub {
            my $c = shift;
            my $frag = shift;
            return qq[http://www.w3.org/1999/02/22-rdf-syntax-ns#$frag]
        });
    $app->helper(property_to_iri => sub {
            my $c = shift;
            my $prop = shift;
            if ($prop =~ /^(prov):(.*)$/) {
                return qq[http://www.w3.org/ns/$1#$2];
            }
            if ($prop =~ /^(dc):(.*)$/) {
                return qq[http://purl.org/$1/terms/$2];
            }
            return $prop;
        });
    $app->helper(all_reports => sub {
            return @{ Tuba::DB::Object::Report::Manager->get_objects(all => 1, sort_by => 'identifier') };
        });
    $app->helper(default_report => sub {
            my $c = shift;
            my $obj;
            $obj = Tuba::DB::Object::Report->new(identifier => 'nca3')->load(speculative => 1) and return $obj;
            $obj = Tuba::DB::Object::Report->new(identifier => 'nca3draft')->load(speculative => 1) and return $obj;
            return Tuba::DB::Object::Report->new(identifier => 'no default report');
        });
    $app->helper(current_report => sub {
            my $c = shift;
            my $identifier = shift || $c->stash('report_identifier') || 'nca3';
            my $obj = Tuba::DB::Object::Report->new(identifier => $identifier);
            $obj->load(speculative => 1) and $obj->_public and return $obj;
            $obj = Tuba::DB::Object::Report->new(identifier => 'nca3draft');
            $obj->load(speculative => 1) and $obj->_public and return $obj;
            return Tuba::DB::Object::Report->new(identifier => 'no report');
        });
    $app->helper(current_chapter => sub {
            my $c = shift;
            my $report = $c->current_report;
            return unless $report && $report->identifier ne 'no report';
            my $chapter_identifier = $c->stash('chapter_identifier') or return;
            my $chapter = Tuba::DB::Object::Chapter->new(identifier => $chapter_identifier, report_identifier => $report->identifier);
            $chapter->load(speculative => 1) or return;
            return $chapter;
        });
    $app->helper(elide => sub {
            my $c = shift;
            my $str = shift;
            my $len = shift or die "missing length";
            return $str if !$str || length($str) < $len;
            return substr($str,0,$len-3).'...';
        });
    $app->helper(labelize => sub {
            my $c = shift;
            my $str = shift;
            # Return a label for a database column.
            $str =~ s/_identifier//;
            $str =~ s/_dt$/_date/;
            $str =~ s/_code//;
            $str =~ s/_/ /g;
            return $str;
        });
    $app->helper(render_partial_ttl => sub {
            my $c = shift;
            my $table = shift || die "need table";
            return $c->render_to_string("$table/object", format => 'ttl')
                || $c->render_to_string("object", format => 'ttl');
        });
    $app->helper(render_ttl_as => sub {
            my $c = shift;
            my $ttl = shift;
            my $format = shift;
            my $conv = Tuba::Converter->new(
                    ttl  => $ttl,
                    base => $c->req->url->base->to_abs,
                    url  => $c->req->url,
                );
            $c->render( data => $conv->output( format => $format, title => $c->stash('title') ));
        });
    $app->helper(uris_to_hrefs => sub {
            my $c = shift;
            my $output = shift;
            my $suffix = shift; # Suffix to append
            my $base = $c->req->url->base;
            URI::Find->new(sub {
                    my ($uri, $orig) = @_;
                    $uri .= ".$suffix" if $suffix && $orig =~ /^\Q$base\E/;
                    return qq[<a href="$uri">$orig</a>];
                })->find(\$output, \&xml_escape );
            return $output;
        });
    $app->helper( expand_turtle_prefixes => sub {
            my $c = shift;
            my $str = shift;
            my %pre = $c->turtle_namespaces;
            my $re = join '|', keys %pre;
            $str =~ s[ ($re):(\w+)\b][ <a target=ontology class="ontology" alt="$pre{$1}$2" title="$pre{$1}$2" href="$pre{$1}$2">$1:$2</a>]g;
            return $str;
        });
    $app->helper(render_partial_ttl_as => sub {
            my $c = shift;
            my $table = shift;
            my $format = shift;
            my $ttl = $c->render_partial_ttl($table);
            $c->render_ttl_as($ttl,$format);
        });
    $app->helper(detect_format => sub {
            # Taken from Mojolicious::Controller::respond_to
            my $c = shift;
            my $stash   = $c->stash;
            return $stash->{format} if $stash->{format}; 
            my @formats = @{$c->app->types->detect($c->req->headers->accept, $c->req->is_xhr)};
            unless (@formats) {
                my $format = $stash->{format} || $c->req->param('format');
                push @formats, $format ? $format : $app->renderer->default_format;
            }
            return $formats[0];
        });
    $app->helper(ontology_url => sub {
            my $c = shift;
            my $str = shift or return;
            my ($namespace,$frag) = split /:/, $str;
            return unless $namespace;
            my $gcis = $c->req->url->base->to_abs;
            $gcis =~ s/^https:/http:/;
            my %map = (
              prov   => q<http://www.w3.org/ns/prov#>,
              bibo   => q<http://purl.org/ontology/bibo/>,
              dc     => q<http://purl.org/dc/elements/1.1/>,
              dct    => q<http://purl.org/dc/terms/>,
              dctype => q<http://purl.org/dc/dcmitype/>,
              foaf   => q<http://xmlns.com/foaf/0.1/>,
              gcis   => qq<$gcis/gcis.owl#>,
              org    => q<http://www.w3.org/ns/org#>,
              prov   => q<http://www.w3.org/ns/prov#>,
              rdf    => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
              rdfs   => q<http://www.w3.org/2000/01/rdf-schema#>,
              xml    => q<http://www.w3.org/XML/1998/namespace>,
              xsd    => q<http://www.w3.org/2001/XMLSchema#>,
              cito   => #q<http://purl.org/spar/cito/>, # redirect ignores trailing part of url
                        q<http://www.essepuntato.it/lode/http://purl.org/spar/cito/>,
              biro   => #q<http://purl.org/spar/biro/>,
                        q<http://www.essepuntato.it/lode/http://purl.org/spar/biro/>,
            );
            my $base = $map{$namespace} or return;
            return $base.$frag;
        });
    $app->helper(ontology_human => sub {
            my $c = shift;
            my $full = shift or return;
            # turn prov:wasInformedBy into "was informed by"
            # turn prov:wasDerivedFrom into "was derived from";
            my ($ns,$str) = split /:/, $full;
            $str = decamelize(ucfirst $str);
            $str =~ s/_/ /g;
            return $str;
    });
    $app->helper(ontology_human_pl => sub {
            my $c = shift;
            my $full = shift or return;
            my $count = shift;
            my $str = $c->ontology_human($full);
            return PL_V($str,$count);
            return $str;
        } );
 
    $app->helper(uri => sub {
        my $c = shift;
        my $obj = shift or return "";
        my $uri = $obj->uri($c,{ tab => 'show' }) or die "no url for $obj";
        return $uri->to_abs;
    });
    $app->helper(new_id => sub {
            state $id = 1;
            $id++; $id = 1 if $id > 1_000;
            $id;
        });
    $app->helper(min => sub {
            my $c = shift;
            return min(@_);
        });
    $app->helper(str_to_obj => sub {
         my $c = shift;
         my $str = shift;
         return $c->Tuba::Search::autocomplete_str_to_object($str);
     });
    $app->helper(uri_to_obj => sub {
         my $c = shift;
         my $uri = shift or die "missing uri";

         my $obj;
         for ($uri) {
             m[^/report/([^/]+)/chapter/([^/]+)/figure/([^/]+)$]  and $obj = Tuba::DB::Object::Figure->new(report_identifier => $1, identifier => $3);
             m[^/report/([^/]+)/chapter/([^/]+)/finding/([^/]+)$] and $obj = Tuba::DB::Object::Finding->new(report_identifier => $1, identifier => $3);
             m[^/report/([^/]+)/chapter/([^/]+)/table/([^/]+)$]   and $obj = Tuba::DB::Object::Table->new(report_identifier => $1, identifier => $3);
             m[^/report/([^/]+)/chapter/([^/]+)$] and $obj = Tuba::DB::Object::Chapter->new(report_identifier => $1, identifier => $2);
             m[^/report/([^/]+)/figure/([^/]+)$]  and $obj = Tuba::DB::Object::Figure->new(report_identifier => $1, identifier => $2);
             m[^/report/([^/]+)/finding/([^/]+)$] and $obj = Tuba::DB::Object::Finding->new(report_identifier => $1, identifier => $2);
             m[^/report/([^/]+)/table/([^/]+)$]  and $obj = Tuba::DB::Object::Table->new(report_identifier => $1, identifier => $2);
             m[^/organization/([^/]+)$]  and $obj = Tuba::DB::Object::Organization->new(identifier => $1);
             m[^/instrument/([^/]+)$]    and $obj = Tuba::DB::Object::Instrument->new(identifier => $1);
             m[^/platform/([^/]+)$] and $obj = Tuba::DB::Object::Platform->new(identifier => $1);
             m[^/person/([^/]+)$]   and $obj = Tuba::DB::Object::Person->new(id => $1);
             m[^/article/(.*)$]     and $obj = Tuba::DB::Object::Article->new(identifier => $1);
             m[^/activity/([^/]+)$] and $obj = Tuba::DB::Object::Activity->new(identifier => $1);
             m[^/journal/([^/]+)$]  and $obj = Tuba::DB::Object::Journal->new(identifier => $1);
             m[^/book/([^/]+)$]     and $obj = Tuba::DB::Object::Book->new(identifier => $1);
             m[^/dataset/([^/]+)$]  and $obj = Tuba::DB::Object::Dataset->new(identifier => $1);
             m[^/image/([^/]+)$]    and $obj = Tuba::DB::Object::Image->new(identifier => $1);
             m[^/array/([^/]+)$]    and $obj = Tuba::DB::Object::Array->new(identifier => $1);
             m[^/webpage/([^/]+)$]  and $obj = Tuba::DB::Object::Webpage->new(identifier => $1);
             m[^/generic/([^/]+)$]  and $obj = Tuba::DB::Object::Generic->new(identifier => $1);
             m[^/report/([^/]+)$]   and $obj = Tuba::DB::Object::Report->new(identifier => $1);
         }
         if ($obj && $obj->load(speculative => 1)) {
             return $obj;
         }
         return;
    });
    $app->helper(uri_to_pub => sub {
            my $c = shift;
            my $uri = shift;
            my $obj = $c->uri_to_obj($uri) or return;
            my $pub = $obj->get_publication(autocreate => 1);
            $pub->save(audit_user => $c->user) unless $pub->id;
            return $pub;
        });
    $app->helper(db_labels => sub {
            my $c = shift;
            my $table = shift;
            return [ map [ $_->label, $_->identifier ],
                @{ $c->orm->{$table}->{mng}->get_objects(all => 1) } ];
        }); 
    $app->helper(include_first => \&_include_first);
    $app->helper(look_similar => sub { my $c = shift; _look_similar(@_);  });
    $app->helper(plural => sub {
            my $c = shift;
            my $what = shift;
            return 'people' if $what eq 'person';
            return $what.'s' if $what =~ /array/i;
            if ($what =~ s/y$/ies/) {
                return $what;
            }
            return $what.'s';
        });
    $app->helper(to_textfield_value => sub {
            my $c = shift;
            my $val = shift;
            return "" unless defined($val);
            return $val unless ref($val);
            if (ref($val) =~ /DateTime::Duration/) {
                return DateTime::Format::Human::Duration->new()->format_duration($val);
            }
            return "$val";
        });
    $app->helper(human_duration => sub {
            my $c = shift;
            my $val = shift;
            return "" unless defined($val) && length($val);
            return DateTime::Format::Human::Duration->new()->format_duration($val);
        });
    $app->helper(human_date => sub {
            my $c = shift;
            my $val = shift;
            return "" unless defined($val) && ref($val);
            return $val unless ref($val) eq 'DateTime';
            return $val->strftime('%B %d, %Y (%H:%M %p)') if $val->hms ne '00:00:00';
            return $val->strftime('%B %d, %Y');
        });
    $app->helper(human_size => sub {
            my $c = shift;
            my $val = shift;
            return format_bytes($val, precision => 0);
        });
    $app->helper(default_html_relationships => sub {
        my $c = shift;
        my $obj = shift;
        my $rels = ( $c->stash('relationships') || $obj->meta->relationships );
        my @methods = grep {
                ( $_ !~ /^_/ ) && ($_ !~ /^(contributors|report|chapter)$/)
            } map $_->name, @$rels;
        return wantarray ? @methods : \@methods;
    });
    $app->helper(sorted_list => sub {
        my $c = shift;
        my $object = shift;
        my $method = shift;
        my $sorters = $c->stash('sorters');
        my $got = $object->$method;
        if (ref($got) eq 'ARRAY') {
           if (my $sorter = $sorters->{$method}) {
              @$got = sort $sorter @$got;
           } else {
              @$got = sort { $a->sortkey cmp $b->sortkey } @$got;
           }
        } elsif ($got) {
          $got = [ $got ];
        } else {
          $got = [];
        }
        return wantarray ? @$got : $got;
    });
    $app->helper(db_identifiers => sub {
            my $c = shift;
            my $table = shift;
            my @ids = map $_->identifier,
                @{ $c->orm->{$table}->{mng}->get_objects(all => 1, sort_by => "identifier") };
            return wantarray ? @ids : \@ids;
    }); 
    $app->helper(doc_for => sub {
            my $c = shift;
            my $route_name = shift;
            state $mng //= Tuba::DocManager->new();
            return $mng->find_doc($route_name);
    });
    $app->helper(url_host => sub {
            my $c = shift;
            my $url = shift or return "";
            my $obj = Mojo::URL->new($url) or return $url;
            return ($obj->host || $url);
        });
    $app->helper(tbibs_to_links => sub {
            my $c = shift;
            my $str = shift;
            return "" unless $str && length($str);
            my $out;
            my $i = 1;
            my @pieces = split qr[<tbib>([^<]+)</tbib>], $str;
            while (@pieces) {
                my $next = shift @pieces;
                $next =~  s[<sup>,</sup>][ ];
                $out .= b($next)->xml_escape;
                my $tbib = shift @pieces;
                next unless $tbib;
                $out .= qq[<a href="/reference/$tbib" data_tbib='$tbib' class="tbib badge badge-default">$tbib</a>];
                $i++;
            }
            return b($out);
        });
    $app->helper(no_tbibs => sub {
            my $c = shift;
            my $str = shift or return "";
            $str =~ s[<tbib>([^<]+)</tbib>][]g;
            $str =~ s[<sup>([^<]+)</sup>][]g;  # sometimes accompany tbibs
            return $str;
        });
    $app->helper(tl => sub {
            # escape a turtle literal enclosed in double quotes
            # http://www.w3.org/TR/turtle/#literals
            my $c = shift;
            my $str = shift;
            return "" unless defined($str) && length($str);
            # Deprecated since .tut templates escape turtle (see Tuba.pm).
            return $str;
        });
    $app->helper( fix_url => sub {
            my $c = shift;
            my $to = shift or return;
            $to = "http://$to" if $to !~ /:\/\//;
            return unless $to =~ m[^(https?|ftp)://];
            return $to;
        });
    $app->helper( filter_lines_with => sub {
            # Remove lines containing a string or matching a regexp.
            my $c = shift;
            my $what = shift;
            my $block = shift;
            my $regex = ref($what) eq 'Regexp' ? $what : qr/\Q$what\E/;
            no warnings 'uninitialized';
            my $before = $block->();
            my @lines = grep { $_ !~ /$regex/ } split /\n/, $before;
            return b(join "\n", @lines);
        });
    $app->helper( empty_predicate => sub {
            my $c = shift;
            return qr[
                       \                 # a space
                       ""                # empty quotes
                       (?:"""")?         # four more empty quotes (for literals with newlines)
                        (?:\^\^xsd:
                           (?:[a-zA-Z]+) # optional type
                        )?
                        ;$                    # end of line
                      ]x;
        });
    $app->helper(external_link => sub {
            my $c = shift;
            my $url = shift or return "";
            return $url unless $url =~ /^(http|ftp)/;
            return $c->link_to($url, $url, target => "_blank");
        });
    $app->helper(turtle_namespaces => sub {
     my $c = shift;
     my $sources = shift;
     state $namespaces = [
      # [ abbrev => prefix => src  ],
        [  bibo     => 'http://purl.org/ontology/bibo/' => 'http://eelst.cs.unibo.it/apps/LODE/source?url=http://purl.org/spar/biro', ],
        [  dbpedia  => 'http://dbpedia.org/resource/', ],
        [  dbpprop  => 'http://dbpedia.org/property/', ],
        [  dbpedia_owl => 'http://dbpedia.org/ontology/', ],
        [  dc       => 'http://purl.org/dc/elements/1.1/' => 'http://dublincore.org/2012/06/14/dcelements.rdf', ],
        [  dcterms  => 'http://purl.org/dc/terms/' => 'http://dublincore.org/2012/06/14/dcterms.rdf', ],
        [  dcmitype => 'http://purl.org/dc/dcmitype/' => 'http://dublincore.org/2012/06/14/dctype.rdf', ],
        [  foaf     => 'http://xmlns.com/foaf/0.1/'  => 'http://xmlns.com/foaf/spec/index.rdf', ],
        [  gcis     => 'http://data.globalchange.gov/gcis.owl#' => 'http://data.globalchange.gov/owl/gcis.ttl', ],
        [  org      => 'http://www.w3.org/ns/org#' => 'http://www.w3.org/ns/org', ],
        [  prov     => 'http://www.w3.org/ns/prov#' => 'http://www.w3.org/ns/prov.owl', ],
        [  owl      => 'http://www.w3.org/2002/07/owl#' => 'http://www.w3.org/2002/07/owl#', ],
        [  rdf      => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', ],
        [  rdfs     => 'http://www.w3.org/2000/01/rdf-schema#' => 'http://www.w3.org/2000/01/rdf-schema#', ],
        [  xml      => 'http://www.w3.org/XML/1998/namespace', ],
        [  xsd      => 'http://www.w3.org/2001/XMLSchema#', ],
        [  dwc      => 'http://rs.tdwg.org/dwc/terms/' => 'http://rs.tdwg.org/dwc/xsd/tdwg_dwc_simple.xsd', ],
        [  doco     => 'http://purl.org/spar/doco' => 'http://eelst.cs.unibo.it/apps/LODE/source?url=http://purl.org/spar/doco', ],
        [  cito     => 'http://purl.org/spar/cito/' => 'http://eelst.cs.unibo.it/apps/LODE/source?url=http://purl.org/spar/cito', ],
        [  biro     => 'http://purl.org/spar/biro/' => 'http://eelst.cs.unibo.it/apps/LODE/source?url=http://purl.org/spar/biro', ],
        [  datacite => 'http://purl.org/spar/datacite/' => 'http://eelst.cs.unibo.it/apps/LODE/source?url=http://purl.org/spar/datacite', ],
        [  co       => 'http://purl.org/co/' => 'http://eelst.cs.unibo.it/apps/LODE/source?url=http://purl.org/co', ],
        [  frbr     => 'http://purl.org/vocab/frbr/core#' => 'http://vocab.org/frbr/core.rdf', ],
        [  dcat     => 'http://www.w3.org/ns/dcat#' => 'http://www.w3.org/ns/dcat.rdf', ],
        [  vivo     => 'http://vivoweb.org/ontology/core#' => 'http://vivoweb.org/files/vivo-isf-public-1.6.owl#', ],
        [  ext      => 'http://http://sweet.jpl.nasa.gov/2.3/propTime.owl#' => 'http://sweet.jpl.nasa.gov/2.3/propTime.owl', ],
        [  geo      => 'http://www.w3.org/2003/01/geo/wgs84_pos#' => 'http://www.w3.org/2003/01/geo/wgs84_pos#', ],
        [  fabio    => 'http://purl.org/spar/fabio/' => 'http://eelst.cs.unibo.it/apps/LODE/source?url=http://purl.org/spar/fabio', ],
        [  schema   => 'http://schema.org/', ],
        [  skos     => 'http://www.w3.org/2004/02/skos/core#' => 'http://www.w3.org/TR/skos-reference/skos.rdf', ],
        [  place    => 'http://purl.org/ontology/places#' => 'http://vocab.org/places/schema.rdf', ],
        [  lemon    => 'http://lemon-model.net/lemon#', ],
      ];
     return ( map {( $_->[0] => $_->[2] )} @$namespaces ) if $sources;
     return ( map {( $_->[0] => $_->[1] )} @$namespaces );
    });
    $app->helper(valid_gcid => sub {
            my $c = shift;
            my $gcid = shift;
            my $obj = $c->uri_to_obj($gcid) and return 1;
            return 0;
        });
    $app->helper(A => sub {
            my $c = shift;
            my $word = shift;
            return A($word);
        });
    $app->helper(pl => sub {
            my $c = shift;
            my ($word,$count,$no_numbers) = @_;
            $count //= 0;
            Lingua::EN::Inflect::classical(names => 0);
            my $pl = PL($word,$count);
            return $pl if $no_numbers;
            my $fmted = Number::Format->new->format_number($count);
            return "$fmted $pl";
        });
    $app->helper(gen_id => sub {
            my $c = shift;
            my $word = shift;
            return b($word)->md5_sum;
        });
    $app->helper(map_url => sub {
            my $c = shift;
            my %a = @_;
            my ($lat,$lon) = @a{qw/lat lon/};
            my $url = Mojo::URL->new("http://tools.wmflabs.org/geohack/geohack.php");
            my $params = sprintf('%f_N_%f_E_',$lat,$lon);
            return $url->query(params => $params);
        });
    $app->helper(get_counts => sub {
            my $c = shift;
            my $table = shift;
            my $count = $c->orm->{$table}->{mng}->get_objects_count;
            return $count;
        });
    $app->helper(format_number => sub {
            my $c = shift;
            my $num = shift;
            return Number::Format->new->format_number($num, @_);
        });
    $app->helper(keysort => sub {
            my $c = shift;
            my ($block, @thingies) = @_;
            return keysort(sub { $block->() }, @thingies);
        });
    $app->helper(to_url => sub {
            my $c = shift;
            my $path = shift;
            my $url = $c->req->url->clone;
            $url->path($path);
            return $url->to_abs;
        });
    $app->helper(is_prod => sub {
            my $c = shift;
            return 0 unless $c->app->mode eq 'production';
            return 0 unless $c->req->url->clone->to_abs->host eq 'data.globalchange.gov';
            return 1;
        });
}
1;
1;
