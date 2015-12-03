#!/usr/bin/env perl

=head1 NAME

Tuba -- Tremendously Useful Backend API

=head1 DESCRIPTION

Tuba provides a RESTful API to GCIS data.

=head1 CONFIGURATION

    %# This is a sample config file for Tuba.  This file should be
    %# either in the TUBA_CONFIG environment variable, in the current
    %# directory, or in /usr/local/etc/Tuba.conf.

    %# This file is a Mojo::Template of a YAML document.
    %# (see 'perldoc Mojo::Template' for more info)

    hypnotoad :
        workers : 5
        listen :
           - http://*:8080

    image_upload_dir : /var/www/assets

    asset_path : /assets
    # for development :
    asset_remote_fallback : http://data.globalchange.gov/assets

    database :
        dbname   : gcis
        schema   : gcis_metadata
        host     : 
        port     :
        username :
        password :

    read_only : 0
    hide_login_link : 0
    google_analytics :
        id : UA-12345678-9
        domain : example.gov

    auth :
        secret : this_should_be_replaced_with_a_server_secret
        valid_users :
            brian : tuba
            andrew : tuba
        google_secrets_file : <%= $ENV{HOME} %>/gcis/tuba/client_secrets.json

    authz :
        update :
            bduggan2@gmail.com : 0
            bduggan@usgcrp.gov : 1

=cut

package Tuba;
use Mojo::Base qw/Mojolicious/;
use Mojo::ByteStream qw/b/;
use Tuba::Converter;
use Tuba::Log;
use Tuba::Util qw/set_config new_uuid/;
use Path::Class qw/file/;
use Data::Rmap qw/rmap_all/;
use strict;

our $VERSION = '1.38';
our @supported_formats = qw/json yaml ttl html nt rdfxml dot rdfjson jsontriples svg txt thtml csv/;

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
    my $config = $app->config;
    $ENV{MOJO_MAX_MESSAGE_SIZE} = 300 * 1024 * 1024 * 1024 unless $config->{read_only};
    $ENV{MOJO_INACTIVITY_TIMEOUT} = 300 unless $config->{read_only};
    set_config($app->config);
    unshift @{$app->plugins->namespaces}, 'Tuba::Plugin';
    $app->plugin( 'db', ( $app->config('database') || die "no database config" ) );
    if (my $path = $app->config('log_path')) {
        $app->log->info("logging to $path");
        $app->log(Mojo::Log->new(path => $path));
    }
    $app->plugin('Auth' => $app->config('auth'));
    $app->plugin('TubaHelpers' => { supported_formats => \@supported_formats });

    # Renderers
    $app->plugin(EPRenderer => {name => 'tut', template => {escape => sub {
            my $str = shift;
            return "" unless defined($str) && length($str);
            return $str if ref($str) eq 'Mojo::ByteStream';
            $str =~ s/"/\\"/g;
            $str =~ s/\n/\\n/g;
            $str =~ s/\r/\\r/g;
            return $str;
        }}});
    $app->renderer->add_handler(json_canonical => sub {
            my ($r,$c,$o) = @_;
            my $j = $c->stash('jsonxs');
            rmap_all { $_ = "$_" if ref($_) && ref($_) eq 'Mojo::ByteStream' } \$j;
            $$o = JSON::XS->new->canonical(1)->convert_blessed->encode($j);
        });

    # Hooks
    $app->hook(after_dispatch => sub {
        my $c = shift;
        $c->res->headers->header('Access-Control-Allow-Origin' => '*');
        $c->res->headers->header('X-API-Version' => $Tuba::VERSION );
        if (my $id = $c->session('id')) {
            $c->res->headers->etag(qq["$id"]) if $c->req->method =~ /^(POST|PUT)$/;
        }
    } );
    $app->hook(before_dispatch => sub {
        # Support X-Forwarded-Base in reverse proxy setup
        my $c = shift;
        my $forward_base = $c->req->headers->header('X-Forwarded-Base');
        $c->req->url->base(Mojo::URL->new($forward_base)) if $forward_base;

        # Support various accept headers for gcis.owl
        return 1 unless $c->req->url->path eq '/gcis.owl';
        if ($c->accepts('html')) {
            $c->res->headers->content_type("text/html");
            return 1;
        }
        $c->respond_to(
            ttl => sub {
                my $c = shift;
                $c->res->headers->content_type("text/turtle");
                $c->app->static->serve($c,"owl/gcis.ttl");
                $c->rendered;
            },
            nt => sub {
                my $c = shift;
                $c->res->headers->content_type("text/plain");
                $c->render_ttl_as( $c->app->static->file("owl/gcis.ttl")->slurp,
                    'ntriples');
            },
            rdfxml => sub {
                my $c = shift;
                $c->res->headers->content_type("application/rdf+xml");
                $c->render_ttl_as( $c->app->static->file("owl/gcis.ttl")->slurp,
                    'rdfxml');
            },
        );
        return 1;
    });
    $app->hook(after_static => sub {
           my $c = shift;
           $c->res->headers->content_disposition('attachment;') if $c->param('download');
    });
    $app->hook(before_render => sub {
            # If there is an object, set the stash value corresponding to its moniker.
            my $c = shift;
            return if $c->stash('tuba.moniker_set');
            my $obj = $c->stash('object') or return;
            my $moniker = $obj->moniker;
            if (!defined($c->stash($moniker))) {
                $c->stash($moniker => $obj);
            }
            $c->stash('tuba.moniker_set' => 1);
        });

    # Shortcuts (see Mojolicious::Guides::Routing)
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
      if ($@) {
          unless ($@ =~ /^Can't locate/) {
              warn "loading $controller failed ---------- $@\n";
              die $@;
          }
          $app->log->debug("did not load $controller : $@");
      }
      my $cname = $controller;
      $cname =~ s/Tuba:://;
      $cname = b($cname)->decamelize;

      # Build bridges and routes.
      my $resource = $r->route("$path_base")->to("$cname#");
      $resource->get->to('#list')->name("list_$name") unless $opts->{no_list};
      my $select;
      my @restrict = $opts->{restrict_identifier} ? ( $identifier => $opts->{restrict_identifier} ) : ();
      my %defaults = $opts->{defaults} ? %{ $opts->{defaults} } : ();
      if ($opts->{wildcard}) {
        my $reserved = qr[^(?:form/update
                                (?:_prov|_rel|_files|_contributors)?
                             |form/create
                             |reference
                             |update
                                (?:_prov|_rel|_files|_contributors)?
                             |put_files
                             |history
                           )
                         ]x;
        for my $format (@supported_formats) {
                $resource->get("(*$identifier).$format" => \@restrict => { format => $format } )
                         ->over(not_match => { $identifier => $reserved })
                         ->to('#show')->name("_show_${name}_$format");
        }
        $resource->get("*$identifier" => \@restrict => \%defaults )->over(not_match => { $identifier => $reserved })->to('#show')->name("show_$name");
      } else {
        $resource->get(":$identifier" => \@restrict => \%defaults )->to('#show')->name("show_$name");
        $select = $resource->under(":$identifier")->to('#select')->name("select_$name");
      }

      return $select if $config->{read_only};

      my $authed = $r->under("/$path_base")->to(cb => sub {
              my $c = shift;
              return $c->deny_auth unless $c->auth && $c->authz(role => 'update');
              return 1;
          })->name("authed_select_$name");
      $authed->post->to("$cname#create")->name("create_$name");
      $authed->get('/form/create')->to("$cname#create_form")->name("create_form_$name");

      if ($opts->{wildcard}) {
          $authed->get("/form/update/*$identifier" => \%defaults)      ->to("$cname#update_form")->name("update_form_$name");
          $authed->get("/form/update_prov/*$identifier" => \%defaults) ->to("$cname#update_prov_form")->name("update_prov_form_$name");
          $authed->get("/form/update_rel/*$identifier" => \%defaults)  ->to("$cname#update_rel_form")->name("update_rel_form_$name");
          $authed->get("/form/update_files/*$identifier" => \%defaults)->to("$cname#update_files_form")->name("update_files_form_$name");
          $authed->get("/form/update_contributors/*$identifier" => \%defaults)->to("$cname#update_contributors_form")->name("update_contributors_form_$name");
          $authed->get("/history/*$identifier" => \%defaults)          ->to("$cname#history")    ->name("history_$name");
          $authed->delete("*$identifier" => \%defaults)                ->to("$cname#remove")     ->name("remove_$name");
          $authed->post("*$identifier" => \%defaults)->over(not_match => { $identifier => qr[^(?:prov|rel|keywords|files|contributors)/] })
                                                   ->to("$cname#update")     ->name("update_$name");
          $authed->post("/prov/*$identifier")      ->to("$cname#update_prov")->name("update_prov_$name");
          $authed->post("/rel/*$identifier")       ->to("$cname#update_rel")->name("update_rel_$name");
          $authed->post("/keywords/*$identifier")  ->to("$cname#update_keywords")->name("update_keywords_$name");
          $authed->post("/regions/*$identifier")   ->to("$cname#update_regions")->name("update_regions_$name");
          $authed->post("/files/*$identifier")     ->to("$cname#update_files")->name("update_files_$name");
          $authed->post("/contributors/*$identifier")     ->to("$cname#update_contributors")->name("update_contributors_$name");
          $authed->put("/files/*$identifier/#filename") # a default filename for PUTs would be ambiguous.
                                                   ->to("$cname#put_files")->name("put_files_$name");
      } else {
          $authed->get("/form/update/:$identifier")                    ->to("$cname#update_form")->name("update_form_$name");
          $authed->get("/form/update_prov/:$identifier" => \%defaults) ->to("$cname#update_prov_form")->name("update_prov_form_$name");
          $authed->get("/form/update_rel/:$identifier" => \%defaults)  ->to("$cname#update_rel_form")->name("update_rel_form_$name");
          $authed->get("/form/update_files/:$identifier" => \%defaults)->to("$cname#update_files_form")->name("update_files_form_$name");
          $authed->get("/form/update_contributors/:$identifier" => \%defaults)->to("$cname#update_contributors_form")->name("update_contributors_form_$name");
          $authed->get("/history/:$identifier" => \%defaults)    ->to("$cname#history")    ->name("history_$name");
          $authed->delete(":$identifier" => \%defaults)          ->to("$cname#remove")     ->name("remove_$name");
          $authed->post(":$identifier" => \%defaults)            ->to("$cname#update")     ->name("update_$name");
          $authed->post("/prov/:$identifier" => \%defaults)      ->to("$cname#update_prov")->name("update_prov_$name");
          $authed->post("/rel/:$identifier" => \%defaults)       ->to("$cname#update_rel")->name("update_rel_$name");
          $authed->post("/keywords/:$identifier" => \%defaults)  ->to("$cname#update_keywords")->name("update_keywords_$name");
          $authed->post("/regions/:$identifier" => \%defaults)   ->to("$cname#update_regions")->name("update_regions_$name");
          $authed->post("/files/:$identifier" => \%defaults)     ->to("$cname#update_files")->name("update_files_$name");
          $authed->post("/contributors/:$identifier" => \%defaults)     ->to("$cname#update_contributors")->name("update_contributors_$name");
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
        $c->respond_to(
          text => sub { shift->render( text => ( join "\n", (map new_uuid(), 1..$count) ) ) },
          html => sub { shift->render( text => ( join "\n", (map new_uuid(), 1..$count) ) ) },
          json => sub { shift->render( json => [ map new_uuid(), 1..$count ] ) },
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
    my $ch = $r->lookup('select_chapter');

    $ch->resource('finding');
    $ch->resource('figure');
    $ch->resource('table');

    # Report (finding|figure|table)s have no chapter.
    $report->get('/finding')->to('finding#list')->name('list_all_findings');
    $report->get('/figure') ->to('figure#list') ->name('list_all_figures');
    $report->get('/table')  ->to('table#list')  ->name('list_all_tables');
    $report->resource('report_finding', { controller => 'Tuba::Finding', identifier => 'finding_identifier', path_base => 'finding', no_list => 1 });
    $report->resource('report_figure',  { controller => 'Tuba::Figure',  identifier => 'figure_identifier',  path_base => 'figure', no_list => 1 });
    $report->resource('report_table',   { controller => 'Tuba::Table',   identifier => 'table_identifier',   path_base => 'table', no_list => 1 });
    $r->get("/figure")->to("figure#list")->name("list_figures_across_reports");

    # Redirect from generics to specifics.
    $r->get('/publication/:publication_identifier')->to('publication#show')->name('show_publication'); # redirect based on type.
    $r->get('/contributor/:contributor_identifier')->to('contributor#show')->name('show_contributor'); # redirect based on type.

    # Article (which have DOIs so slashes are allowed in the URL)
    $r->resource(article => { wildcard => 1} );

    # Journals, papers.
    $r->resource($_) for qw/journal/;

    # Images (globally unique)
    $r->resource('image');
    $report->get('/image')->to('image#list')->name('list_report_images');

    # array (globally unique)
    $r->resource('array');
    $report->get('/array')->to('array#list');

    # webpage (globally unique)
    $r->resource('webpage');
    $report->get('/webpage')->to('webpage#list');

    # book (globally unique)
    $r->resource('book');
    $report->get('/book')->to('book#list');

    # activity (globally unique)
    $r->resource('activity');

    # platform (globally unique)
    $r->resource('platform');
    $r->resource('instrument');
    $r->lookup('select_platform')->resource('instrument_instance', {
            path_base => "instrument",
            identifier => "instrument_identifier",
        });

    # Person.
    my $person = $r->resource(person => { restrict_identifier => qr/\d+/ } );
    $r->get('/person/:orcid' => [orcid => qr(\d{4}-\d{4}-\d{4}-\d{4})])
      ->to('person#redirect_by_orcid');
    $r->get('/person/:name')->to('person#redirect_by_name');
    $person->get('/contributions/:role_type_identifier/:resource')->to('person#contributions')->name('person_contributions');

    # Organization
    my $organization = $r->resource('organization');
    $r->post('/organization/lookup/name')->to('organization#lookup_name');
    $r->post('/person/lookup/name')->to('person#lookup_name');
    $r->lookup('select_organization')->post('/merge')->to('organization#merge')->name('merge_organization');
    $organization->get('/contributions/:role_type_identifier/:resource')->to('organization#contributions')->name('organization_contributions');

    $r->resource('gcmd_keyword');
    $r->resource('region');
    $r->resource('dataset');
    $r->get("/dataset/lookup/*doi" => [ doi => qr[10\..*$] ])->to('dataset#lookup_doi')->name('dataset_doi');

    # Files.
    $r->resource("file", {no_list => 1});

    # References (bibliographic entries)
    my $reference = $r->resource('reference');
    $r->lookup('authed_select_reference')->post('/match')->to('reference#smartmatch') unless $config->{read_only};
    $r->under('/reference/match')
      ->to(cb => sub {
              my $c = shift;
              return $c->deny_auth unless $c->auth && $c->authz(role => 'update');
              return 1;
        })
      ->post('/:reference_identifier')
      ->to('reference#smartmatch');
    #$r->get("/reference/lookup/:record_number" => [ record_number => qr/\d+/])->to('reference#lookup');
    $r->get('/reference/report/updates')->to('reference#updates_report')->name('reference_updates_report')
        unless $config->{read_only};

    # Publications with references
    for my $resource (qw/report chapter figure finding table webpage book dataset journal/) {
        # TODO: article
        my $route = $r->lookup("select_$resource") or die "bad pub $resource";
        $route->get("/reference")->to("reference#list_for_publication")->name("list_reference_$resource");
        $route->get("/reference/:reference_identifier")->to('reference#show_for_publication')->name("show_reference_$resource");
    }

    # Generic publication.
    $r->resource('generic');

    # Projects, models, model runs, scenarios
    $r->resource('project');
    $r->resource('model');
    $r->resource('model_run');
    $r->resource('scenario');
    $r->get("/model/:model_identifier/run")->to("model_run#list")->name("list_model_runs_for_model");
    $r->get("/scenario/:scenario_identifier/run")->to("model_run#list")->name("list_model_runs_for_scenario");
    $r->get("/model_run/:model_identifier/:scenario_identifier/:range_start/:range_end/:spatial_resolution/:time_resolution/:sequence")
        ->to("model_run#lookup")->name('model_run_lookup');

    # Roles
    $r->resource('role_type');

    # Lexicons
    $r->resource('lexicon');
    my $lex = $r->lookup('select_lexicon');
    $lex->get('/find/:context/*term')->to('exterm#find')->name('find_term');
    $lex->get('/:context/*term')
                   ->over(not_match => { 'context' => qr[list|find|update] })
                   ->to('exterm#find')->name('show_exterm');
    $lex->get('/list/:context')->to('exterm#list_context')->name('lexicon_terms');
    if (my $lex_authed = $r->lookup('authed_select_lexicon')) {
        $lex_authed->post('/:lexicon_identifier/term/new')->to('exterm#create');
        $lex_authed->put('/:lexicon_identifier/:context/*term')->to('exterm#create');
        $lex_authed->delete('/:lexicon_identifier/:context/*term')->to('exterm#remove');
    }

    # Search route.
    $r->get('/search')->to('search#keyword')->name('search');
    $r->get('/gcid_lookup')->to('search#gcid')->name('gcid_lookup');

    # To regenerate the owl file, get this URL :
    # http://ontorule-project.eu/parrot?documentUri=http://orion.tw.rpi.edu/~xgmatwc/ontology-doc/GCISOntology.ttl
    # Then prefix href's for the css at the top with
    #   http://ontorule-project.eu/parrot
    $app->types->type(ttl         => [ 'application/x-turtle', 'text/turtle' ]);
    $app->types->type(nt          => [ 'application/n-triples', 'text/n3', 'text/rdf+n3' ]);
    $app->types->type(jsontriples => [ 'application/ld+json' ]);
    $app->types->type(rdfxml      => [ 'application/rdf+xml' ]);
    $app->types->type(rdfjson     => [ 'application/rdf+json' ]);

    # Tuba-specific routes
    $r->get('/')->to('controller#index')->name('index');
    $r->get('/metrics')->to('controller#index')->name('metrics');
    $r->get('/api_reference')->to('doc#api_reference')->name('api_reference');

    $r->get('/resources')->to('doc#resources')->name('resources');
    $r->get('/examples')->to('doc#examples')->name('examples');
    $r->get('/about')->to('doc#about')->name('about');
    $r->get('/autocomplete')->to('search#autocomplete');
    $r->get('/api' => sub { shift->render(template => 'api/index') })->name('apiref');

    unless ($config->{read_only}) {
        my $authed = $r->under->to(
          cb => sub {
              my $c = shift;
              return $c->deny_auth unless $c->auth && $c->authz(role => 'update');
              return 1;
          }
        );
        $authed->get('/admin')->to(cb => sub { shift->render })->name('admin');
        $authed->get('/watch')->to('report#watch')->name('_watch');
        $r->get('/login')->to('auth#login')->name('login');
        $r->get('/login_pw')->to('auth#login_pw')->name('_login_pw');
        $r->get('/login_key')->to('auth#login_key')->name('_login_key');

        $r->post('/login')->to('auth#check_login')->name('check_login');
        $r->get('/oauth2callback')->to('auth#oauth2callback')->name('_oauth2callback');
        $r->get('/logout')->to(cb => sub { my $c = shift; $c->session(expires => 1); $c->redirect_to('index') });

        $authed->get('/import_form')->to('importer#form')->name('import_form');
        $authed->post('/process_import')->to('importer#process_import')->name('process_import');
    }
    if (my $export = $config->{export}) {
        $export = [ $export ] unless ref $export eq 'ARRAY';
        for my $entry (@$export) {
            my $file = $entry;
            my $path = file($file)->basename;
            -e $file or warn "missing export file $file";
            $r->get("/export/$path" => sub {
                    my $c = shift;
                    -e $file or die "no file $file";
                    $c->reply->asset(Mojo::Asset::File->new(path => $file));
                } );
        }
    }

    $r->post('/calculate_url' => sub {
        my $c = shift;
        my $for = $c->param('_route_name');
        my $route = $c->app->routes->lookup($for) or return $c->reply->not_found;
        my $params = $c->req->params->to_hash;
        delete $params->{_route_name};
        my $got = $c->url_for($for, $params);
        $c->render(json => { path => $got->path });
    } => 'calculate_url');

    $app->routes->get('/debug') if $ENV{TUBA_DEBUG};
    $app->routes->get('/open-search')->name('opensearch');
    unless ($app->mode eq 'production') {
        $app->routes->get('/sparql' => sub {
                my $c = shift;
                my $url = $c->req->url->clone;
                $url->host('gcis-dev-front.joss.ucar.edu');
                $c->redirect_to($url);
            });
    }
}

1;

