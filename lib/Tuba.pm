#!/usr/bin/env perl

=head1 NAME

Tuba -- Tremendously Useful Backend API

=head1 DESCRIPTION

Tuba provides a RESTful API to GCIS data.

=cut

package Tuba;
use Mojo::Base qw/Mojolicious/;

our $VERSION = 0.03;

sub demo {
 my $c = shift;
 my $path = $c->req->url->path;
 $c->respond_to(
            json => sub { shift->render_json({demo => 'data', 'you_requested' => $path }) },
            html => sub { shift->render({text => "<html>demo data, you requested <b>$path</b></html>", format => 'html'}) },
            any  => sub {  my $c = shift; $c->render_text('request type is not supported'.$c->req->headers->to_string) },
        )
};

sub startup {
    my $app = shift;

    $app->secret('aePhoox5Iegh6toeay3ooV9n');

    # Plugins, configuration
    my $conf = './Tuba.conf';
    $app->plugin( 'yaml_config' => { file => $conf } );
    unshift @{$app->plugins->namespaces}, 'Tuba::Plugin';
    $app->plugin( 'db', ( $app->config('database') || die "no database config" ) );

    # Helpers
    $app->helper(base => sub {
        my $c = shift;
        my $base = $c->url_for('index')->path;
        $base =~ s[/$][];
        return $base;
    } );

    # Hooks
    $app->hook(after_dispatch => sub {
        my $c = shift;
        $c->res->headers->header('Access-Control-Allow-Origin' => '*');
    } );
    $app->hook(before_dispatch => sub {
        # Remove path when behind a proxy (see Mojolicious::Guides::Cookbook).
        my $c = shift;
        push @{$c->req->url->base->path}, shift @{$c->req->url->path} if @{ $c->req->url->path };
    }) if $app->mode eq 'production';

    # Shortcuts (see Mojolicious::Guides::Routing)
    $app->routes->add_shortcut(resource => sub {
      my ($r, $name) = @_;
      my $resource = $r->route("/$name")->to("$name#");
      $resource->post->to('#create')->name("create_$name");
      $resource->get->to('#list')->name("list_$name");
      my $identifier = join '_', $name, 'identifier';
      $resource->get(":$identifier")->to('#show')->name("show_$name");
      $resource->bridge(":$identifier")->to(cb => sub { 1; } )->name("select_$name");
      return $resource;
    });

    # Routes
    my $r = $app->routes;

    for my $resource (qw/
        report journal paper
        image
        dataset
        model software
        instrument
        platform
        person organization role
        /) {
        $r->resource($resource);
    }

    $r->lookup('select_report')->resource('chapter');
    $r->lookup('select_report')->resource('figure');


    $r->get('/' => sub {
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
              push @placeholders, $n->[1];
          }
          $trying = $trying->parent;
      }
      $c->stash(placeholders => \@placeholders);
    } => 'index');

    $r->post('/calculate_url' => sub {
        my $c = shift;
        my $for = $c->param('_route_name');
        my $route = $c->app->routes->lookup($for) or return $c->render_not_found;
        my $params = $c->req->params->to_hash;
        delete $params->{_route_name};
        my $got = $c->url_for($for, $params);
        $c->render(json => { path => $got->path });
    } => 'calculate_url');

#    $r->get( '/image/met/:image_identifier')->to('Image#met')->name('image_met');
#    $r->post( '/image_setmet' )->to('Image#setmet')->name('image_setmet');
#    $r->get( '/image_checkmet/:token' )->to('Image#checkmet')->name('image_checkmet');
#    $r->get( '/image/:image_identifier')->to('Image#display')->name("image");
#    $r->get( '/image' )->to('Image#list')->name("image_list");

#    $r->get( '/chapter' )->to('Chapter#list')->name("chapter_list");
#    $r->get( '/chapter/:identifier' )->to('Chapter#view')->name("chapter");
#    $r->get( '/chapter/:chapter_identifier/figure' )->to('Figure#list')->name("chapter_figures");

#    $r->get( '/figure' )->to('Figure#list')->name("figure_list");

#    $r->get( '/report/:report_identifier/chapter/:chapter_identifier/figure/:figure_identifier' => { report_identifier => 'nca2013' } => \&demo => 'figure');
#    $r->get( '/report/:report_identifier/figure/:figure_token' => { report_identifier => 'nca2013' } => \&demo => 'figure_token');
#    $r->get( '/activity/:activity_type/report/:report_identifier/:entity_type/:entity_identifier' => \&demo => 'activity');
#    $r->get( '/algorithm/:algorithm_identifier/abbreviation' => \&demo => 'algorithm');
#    $r->get( '/chapter/:chapter_identifier/key-message/:key_message_identifier' => \&demo => 'key_message');
#    $r->get( '/country/:country_identifier' => \&demo => 'country');
#    $r->get( '/dataset/:dataset_identifier' => \&demo => 'dataset');
#    $r->get( '/instrument/:instrument_identifier' => \&demo => 'instrument');
#    $r->get( '/journal/:journal_identifier' => \&demo => 'journal');
#    $r->get( '/model/:model_identifier' => \&demo => 'model');
#    $r->get( '/organization/:organization_identifier' => \&demo => 'organization');
#    $r->get( '/paper/:paper_identifier' => \&demo => 'paper');
#    $r->get( '/person/:person_identifier' => \&demo => 'person');
#    $r->get( '/platform/:platform_identifier/abbreviation' => \&demo => 'platform');
#    $r->get( '/project/:project_identifier' => \&demo => 'project');
#    $r->get( '/publication/:publication_identifier' => \&demo => 'publication');
#    $r->get( '/publisher/:publisher_identifier' => \&demo => 'publisher');
#    $r->get( '/report/:report_identifier' => \&demo => 'report');
#    $r->get( '/report/:report_identifier/chapter/:chapter_identifier' => \&demo => 'report_chapter');
#    $r->get( '/report/:report_identifier/chapter/:chapter_identifier/traceable-account/:traceable_account_identifier' => \&demo => 'traceable_account');
#    $r->get( '/report/:report_identifier/committee/:committee_identifier' => \&demo => 'committee');;
#    $r->get( '/report/:report_identifier/key-finding/:keyfinding_identifier' => \&demo => 'keyfinding');
#    $r->get( '/role/:role_identifier' => \&demo => 'role');
#    $r->get( '/software/:software_identifier' => \&demo => 'software');

    $app->routes->get('/debug') if $ENV{TUBA_DEBUG};
}

1;

