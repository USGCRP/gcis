#!/usr/bin/env perl

=head1 NAME

Tuba -- Tremendously Useful Backend API

=head1 DESCRIPTION

Tuba provides a RESTful API to GCIS data.

=cut

package Tuba;
use Mojo::Base qw/Mojolicious/;
use Mojo::ByteStream qw/b/;
use Time::Duration qw/ago/;
use Date::Parse qw/str2time/;
use Tuba::Converter;
use Tuba::Log;
use Data::UUID::LibUUID;

our $VERSION = '0.52';
our @supported_formats = qw/json ttl html nt rdfxml dot rdfjson jsontriples svg/;

sub startup {
    my $app = shift;

    $app->plugin('InstallablePaths');

    Tuba::Log->set_logger($app->log);

    # Plugins, configuration
    my $conf =
        $ENV{TUBA_CONFIG}             ? $ENV{TUBA_CONFIG}
      : -f '/usr/local/etc/Tuba.conf' ? '/usr/local/etc/Tuba.conf'
      :                                 './Tuba.conf';
    $app->plugin( 'yaml_config' => { file => $conf } );
    unshift @{$app->plugins->namespaces}, 'Tuba::Plugin';
    $app->plugin( 'db', ( $app->config('database') || die "no database config" ) );
    if (my $path = $app->config('log_path')) {
        $app->log->info("logging to $path");
        $app->log(Mojo::Log->new(path => $path));
    }
    $app->plugin('Auth' => $app->config('auth'));

    # Helpers
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
            my $val = $obj->stringify(@_) || '[missing '.$obj->moniker.']';
            my $uri = $obj->uri($c);
            return $val unless $uri;
            return $c->link_to($val, $uri );
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
            my $obj = shift;
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
            for my $format (@supported_formats) {
                $str =~ s/\.$format$// and last;
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
    $app->helper(current_report => sub {
            my $c = shift;
            my $identifier = shift || $c->stash('report_identifier') || $c->session('report_identifier') || 'nca3draft';
            $c->session(report_identifier => $identifier);
            my $obj = Tuba::DB::Object::Report->new(identifier => $identifier);
            $obj->load(speculative => 1) or return Tuba::DB::Object::Report->new(identifier => 'no_reports_available');
            return $obj;
        });
    $app->helper(elide => sub {
            my $c = shift;
            my $str = shift;
            my $len = shift or die "missing length";
            return $str if !$str || length($str) < $len;
            return substr($str,0,$len-3).'...';
        });
    $app->helper(render_partial_ttl => sub {
            my $c = shift;
            my $table = shift || die "need table";
            return $c->render_maybe(partial => 1, format => 'ttl', template => "$table/object")
                || $c->render(partial => 1, format => 'ttl', template => "object");
        });
    $app->helper(render_ttl_as => sub {
            my $c = shift;
            my $ttl = shift;
            my $format = shift;
            my $conv = Tuba::Converter->new(
                    ttl  => $ttl,
                    base => $c->req->url->base->to_abs
                );
            $c->render( data => $conv->output( format => $format ));
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
            my @formats = @{$c->app->types->detect($c->req->headers->accept, $c->req->is_xhr)};
            push @formats, $c->app->renderer->default_format;
            push @formats, $c->stash('format') if $c->stash('format');
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

    $app->helper(uri => sub {
        my $c = shift;
        my $obj = shift;
        return $obj->uri($c,{ tab => 'show' })->to_abs;
    });
    
    # Hooks
    $app->hook(after_dispatch => sub {
        my $c = shift;
        $c->res->headers->header('Access-Control-Allow-Origin' => '*');
    } );
    $app->hook(before_dispatch => sub {
        # Remove path when behind a proxy (see Mojolicious::Guides::Cookbook).
        my $c = shift;
        push @{$c->req->url->base->path}, shift @{$c->req->url->path}
          if @{ $c->req->url->path->parts } && $c->req->url->path->parts->[0] eq 'api';
        my $forward_base = $c->req->headers->header('X-Forwarded-Base');
        $c->req->url->base(Mojo::URL->new($forward_base)) if $forward_base;
    }) if $app->mode eq 'production';

    # Shortcuts (see Mojolicious::Guides::Routing)
    my @forms;
    # For a given resource we create several routes.  As an
    # example, for the resource 'report' we create :
    #    name           method, path, controller
    #    -----------   --------------------------
    #    list_report        : GET /report                    calls Tuba::Report::list
    #    show_report        : GET /report/:report_identifier calls Tuba;:Report::show
    #  * create_report      : POST /report                   calls Tuba::Report::create
    #  * create_form_report : GET /report/form/create        calls Tuba::Report::create_form
    #  * update_form_report : GET /report/:report_identifier/form/update calls Tuba::Report::update_form
    #  * update_report      : POST /report/:report_identifier/ calls Tuba::Report::update
    #
    #    Also we create and return a route named 'select_report'.  This can be used to
    #    attach other resources lower in the URL path hierarchy.
    #
    #  * Require authentication.
    #
    $app->routes->add_condition(
        not_match => sub {
            my ($route, $c, $captures, $args) = @_;
            for my $k (keys %$args) {
                return undef if $captures->{$k} =~ m{$args->{$k}};
            }
            return 1;
        }
    );
    $app->routes->add_shortcut(resource => sub {
      my ($r, $name, $opts) = @_;
      #
      # $opts is a hash which can have :
      #    restrict_identifier -- a regex for the identifier pattern
      #    wildcard -- means the identifier could have a /
      #    defaults -- default values for routes for this resource.
      #    controller -- controller class
      #    identifier -- name of the stash key for the identifier (tablename + '_identifier')
      #    path_base -- initial path for urls (/tablename)
      #
      my $identifier = $opts->{identifier} || join '_', $name, 'identifier';
      my $controller = $opts->{controller} || 'Tuba::'.b($name)->camelize;
      my $path_base = $opts->{path_base} || $name;

      eval " use $controller ";
      if (!$@) {
         push @forms, "create_form_$name";
      } else {
          unless ($@ =~ /^Can't locate/) {
              warn "loading $controller failed ---------- $@\n";
              die $@;
          }
          # $app->log->debug("did not load $controller");
      }
      my $cname = $controller;
      $cname =~ s/Tuba:://;
      $cname = lc $cname;

      # Build bridges and routes.
      my $resource = $r->route("$path_base")->to("$cname#");
      $resource->get->to('#list')->name("list_$name");
      my $select;
      my @restrict = $opts->{restrict_identifier} ? ( $identifier => $opts->{restrict_identifier} ) : ();
      my %defaults = $opts->{defaults} ? %{ $opts->{defaults} } : ();
      if ($opts->{wildcard}) {
        my $reserved = q[^(?:form/update(?:_prov|_rel|_files)?|form/create|update(?:_rel|files|prov)?|put_files|history/)];
        for my $format (@supported_formats) {
                $resource->get("*$identifier.$format" => \@restrict => { format => $format } )
                         ->over(not_match => { $identifier => $reserved })
                         ->to('#show')->name("_show_${name}_$format");
        }
        $resource->get("*$identifier" => \@restrict => \%defaults )->over(not_match => { $identifier => $reserved })->to('#show')->name("show_$name");
      } else {
        $resource->get(":$identifier" => \@restrict => \%defaults )->to('#show')->name("show_$name");
        $select = $resource->bridge(":$identifier")->to('#select')->name("select_$name");
      }

      my $authed = $r->bridge("/$path_base")->to(cb => sub {
              my $c = shift;
              $c->auth && $c->authz(role => 'update') }
      );
      $authed->post->to("$cname#create")->name("create_$name");
      $authed->get('/form/create')->to("$cname#create_form")->name("create_form_$name");

      if ($opts->{wildcard}) {
          $authed->get("/form/update/*$identifier" => \%defaults)      ->to("$cname#update_form")->name("update_form_$name");
          $authed->get("/form/update_prov/*$identifier" => \%defaults) ->to("$cname#update_prov_form")->name("update_prov_form_$name");
          $authed->get("/form/update_rel/*$identifier" => \%defaults)  ->to("$cname#update_rel_form")->name("update_rel_form_$name");
          $authed->get("/form/update_files/*$identifier" => \%defaults)->to("$cname#update_files_form")->name("update_files_form_$name");
          $authed->get("/history/*$identifier" => \%defaults)          ->to("$cname#history")    ->name("history_$name");
          $authed->delete("*$identifier" => \%defaults)                ->to("$cname#remove")     ->name("remove_$name");
          $authed->post("*$identifier" => \%defaults)->over(not_match => { $identifier => qr[^(?:prov|rel|files)/] })
                                                   ->to("$cname#update")     ->name("update_$name");
          $authed->post("/prov/*$identifier")      ->to("$cname#update_prov")->name("update_prov_$name");
          $authed->post("/rel/*$identifier")       ->to("$cname#update_rel")->name("update_rel_$name");
          $authed->post("/files/*$identifier")     ->to("$cname#update_files")->name("update_files_$name");
          $authed->put("/files/*$identifier/#filename") # a default filename for PUTs would be ambiguous.
                                                   ->to("$cname#put_files")->name("put_files_$name");
      } else {
          $authed->get("/form/update/:$identifier")                    ->to("$cname#update_form")->name("update_form_$name");
          $authed->get("/form/update_prov/:$identifier" => \%defaults) ->to("$cname#update_prov_form")->name("update_prov_form_$name");
          $authed->get("/form/update_rel/:$identifier" => \%defaults)  ->to("$cname#update_rel_form")->name("update_rel_form_$name");
          $authed->get("/form/update_files/:$identifier" => \%defaults)->to("$cname#update_files_form")->name("update_files_form_$name");
          $authed->get("/history/:$identifier" => \%defaults)    ->to("$cname#history")    ->name("history_$name");
          $authed->delete(":$identifier" => \%defaults)          ->to("$cname#remove")     ->name("remove_$name");
          $authed->post(":$identifier" => \%defaults)            ->to("$cname#update")     ->name("update_$name");
          $authed->post("/prov/:$identifier" => \%defaults)      ->to("$cname#update_prov")->name("update_prov_$name");
          $authed->post("/rel/:$identifier" => \%defaults)       ->to("$cname#update_rel")->name("update_rel_$name");
          $authed->post("/files/:$identifier" => \%defaults)     ->to("$cname#update_files")->name("update_files_$name");
          $authed->put("/files/:$identifier/#filename" => {filename => 'unnamed', %defaults })
                                                   ->to("$cname#put_files")->name("put_files_$name");
      }

      return $select;
    });

    my $r = $app->routes;

    # API
    $r->get(
      '/uuid' => sub {
        my $c = shift;
        my $count = $c->param('count') || 1;
        $count = 1 unless $count =~ /^[0-9]+$/;
        return $c->render( text => "sorry, max is 1000 at once" ) if $count > 1000;
        $c->res->headers->content_type('text/plain');
        $c->render(
          text => join "\n", (map new_uuid_string(4), 1..$count)
        );
      } => 'uuid'
    );

    #
    # Various resources, each one gets GET, POST, forms, and other routes.
    # (see the resource helper for more details).
    #

    # Reports.
    my $report = $r->resource('report');

    # Chapters.
    my $chapter = $report->resource('chapter');
    $r->lookup('select_chapter')->resource('finding');
    $r->lookup('select_chapter')->resource('figure');

    # Report (finding|figure)s have no chapter.
    $report->get('/finding')->to('Finding#list')->name('list_all_findings');
    $report->resource('report_finding', { controller => 'Tuba::Finding', identifier => 'finding_identifier', path_base => 'finding' });
    $report->get('/figure')->to('figure#list')->name('list_all_figures');
    $report->resource('report_figure', { controller => 'Tuba::figure', identifier => 'figure_identifier', path_base => 'figure' });

    # Redirect from chapter numbers to names.
    $r->get('/report/:report_identifier/chapter/:chapter_number/figure/:figure_number'
        => [ chapter_number => qr/\d+/, figure_number => qr/\d+/ ]
      )->to('figure#redirect_to_identifier')->name('figure_redirect');

    # Redirect from generics to specifics.
    $r->get('/publication/:publication_identifier')->to('publication#show')->name('show_publication'); # redirect based on type.
    $r->get('/contributor/:contributor_identifier')->to('contributor#show')->name('show_contributor'); # redirect based on type.

    # Article (which have DOIs so slashes are allowed in the URL)
    $r->resource(article => { wildcard => 1} );

    # Journals, papers.
    $r->resource($_) for qw/journal paper/;

    # Images (globally unique)
    $r->resource('image');

    # Metadata processing routes.
    $r->lookup('select_image')->post( '/setmet' )->to('#setmet')->name('image_setmet');
    $r->lookup('select_image')->get( '/checkmet')->to('#checkmet')->name('image_checkmet');

    # Person.
    $r->resource(person => { restrict_identifier => qr/\d+/ } );
    $r->get('/person/:name')->to('person#redirect_by_name');

    # Others, some of which aren't yet implemented.
    $r->resource($_) for qw/dataset model software algorithm activity
                            instrument platform
                            role organization country/;

    # Files.
    $r->resource("file");

    # Bibliographic entry.
    $r->resource('reference');

    # Generic publication.
    $r->resource('generic');

    # Search route.
    $r->get('/search')->to('search#keyword')->name('search');

    # To regenerate the owl file, get this URL :
    # http://ontorule-project.eu/parrot?documentUri=http://orion.tw.rpi.edu/~xgmatwc/ontology-doc/GCISOntology.ttl
    # Then prefix href's for the css at the top with
    #   http://ontorule-project.eu/parrot
    $app->types->type(owl => 'text/html');

    # Tuba-specific routes
    $r->get('/')->to('controller#index')->name('index');
    $r->get('/api_reference' => sub {
      my $c = shift;
      my $trying; if (my $try = $c->param('try')) {
          $trying = $c->app->routes->lookup($try);
      }
      $c->stash(trying => $trying);
      return unless $trying;
      my @placeholders;
      while ($trying) {
          for my $n (@{ $trying->pattern->tree }) {
              next unless @$n==2;
              next unless $n->[0] =~ /^(placeholder|wildcard|relaxed)$/;
              unshift @placeholders, $n->[1];
          }
          $trying = $trying->parent;
      }
      $c->stash(placeholders => \@placeholders);
    } => 'api_reference');

    $r->get('/resources' => 'resources');
    $r->get('/examples' => 'examples');
    $r->get('/autocomplete')->to('search#autocomplete');

    my $authed = $r->bridge->to(cb => sub { my $c = shift; $c->auth && $c->authz(role => 'update')});
    $authed->get('/import')->to(cb => sub { shift->render })->name('import');
    $authed->get('/watch')->to('report#watch')->name('_watch');
    $r->get('/login')->to('auth#login')->name('login');
    $r->get('/login_pw')->to('auth#login_pw')->name('_login_pw');
    $r->get('/login_key')->to('auth#login_key')->name('_login_key');

    $r->post('/login')->to('auth#check_login')->name('check_login');
    $r->get('/oauth2callback')->to('auth#oauth2callback')->name('_oauth2callback');
    $r->get('/logout')->to(cb => sub { my $c = shift; $c->session(expires => 1); $c->redirect_to('index') });

    $authed->get('/import_form')->to('importer#form')->name('import_form');
    $authed->post('/process_import')->to('importer#process_import')->name('process_import');

    $r->post('/calculate_url' => sub {
        my $c = shift;
        my $for = $c->param('_route_name');
        my $route = $c->app->routes->lookup($for) or return $c->render_not_found;
        my $params = $c->req->params->to_hash;
        delete $params->{_route_name};
        my $got = $c->url_for($for, $params);
        $c->render(json => { path => $got->path });
    } => 'calculate_url');

    $app->routes->get('/debug') if $ENV{TUBA_DEBUG};
    $app->routes->get('/open-search')->name('opensearch');
}

1;

