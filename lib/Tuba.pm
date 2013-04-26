#!/usr/bin/env perl

=head1 NAME

Tuba -- Tremendously Useful Backend API

=head1 DESCRIPTION

Tuba provides a RESTful API to GCIS data.

=cut

package Tuba;
use Mojo::Base qw/Mojolicious/;

our $VERSION = 0.01;

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

    $app->plugin( 'yaml_config' => { file => './Tuba.conf' } );
    unshift @{$app->plugins->namespaces}, 'Tuba::Plugin';
    $app->plugin( 'db', ( $app->config('database') || die "no database config" ) );

    $app->secret('aePhoox5Iegh6toeay3ooV9n');

    $app->hook(before_dispatch => sub {
        # Remove path when behind a proxy (see Mojolicious::Guides::Cookbook).
        my $c = shift;
        push @{$c->req->url->base->path}, shift @{$c->req->url->path} if @{ $c->req->url->path };
    }) if $app->mode eq 'production';

    my $r = $app->routes;

    $r->get('/' => sub {
      my $c = shift;
      my $trying;
      if (my $try = $c->param('try')) {
          $trying = $c->app->routes->lookup($try);
      }
      $c->stash(trying => $trying);
      return unless $trying;
      my @placeholders;
      for my $n (@{ $trying->pattern->tree }) {
          next unless @$n==2;
          next unless $n->[0] =~ /^(placeholder|wildcard|relaxed)$/;
          push @placeholders, $n->[1];
      }
      $c->stash(placeholders => \@placeholders);
    } => 'index');

    $r->post('/calculate_url' => sub {
        my $c = shift;
        my $for = $c->param('_route_name');
        my $route = $c->app->routes->lookup($for) or return $c->render_not_found;
        my $params = $c->req->params->to_hash;
        delete $params->{_route_name};
        my $rendered = $route->pattern->render($params);
        $c->render_json({path => $rendered});
    } => 'calculate_url');

    $r->post( '/image/metadata/:image_id')->to('Image#metadata')->name('image_metadata');
    $r->get( '/report/:report_id/chapter/:chapter_id/figure/:figure_id' => { report_id => 'nca2013' } => \&demo => 'figure');
    $r->get( '/report/:report_id/figure/:figure_token' => { report_id => 'nca2013' } => \&demo => 'figure_token');
    $r->get( '/activity/:activity_type/report/:report_id/:entity_type/:entity_id' => \&demo => 'activity');
    $r->get( '/algorithm/:algorithm_name/abbreviation' => \&demo => 'algorithm');
    $r->get( '/chapter/:chapter_id/key-message/:key_message_id' => \&demo => 'key_message');
    $r->get( '/country/:country_abbreviation' => \&demo => 'country');
    $r->get( '/dataset/:dataset_id' => \&demo => 'dataset');
    $r->get( '/image/:image_id' => \&demo => 'image');
    $r->get( '/instrument/:instrument_name' => \&demo => 'instrument');
    $r->get( '/journal/:journal_abbreviation' => \&demo => 'journal');
    $r->get( '/model/:model_abbreviation' => \&demo => 'model');
    $r->get( '/organization/:organization_name' => \&demo => 'organization');
    $r->get( '/paper/:paper_id' => \&demo => 'paper');
    $r->get( '/person/:full_name' => \&demo => 'person');
    $r->get( '/platform/:platform_name/abbreviation' => \&demo => 'platform');
    $r->get( '/project/:project_abbreviation' => \&demo => 'project');
    $r->get( '/publication/:publication_id' => \&demo => 'publication');
    $r->get( '/publisher/:publisher_name' => \&demo => 'publisher');
    $r->get( '/report/:report_id' => \&demo => 'report');
    $r->get( '/report/:report_id/chapter/:chapter_id' => \&demo => 'report_chapter');
    $r->get( '/report/:report_id/chapter/:chapter_id/traceable-account/:traceable_account_id' => \&demo => 'traceable_account');
    $r->get( '/report/:report_id/committee/:committee_abbreviations' => \&demo => 'committee');;
    $r->get( '/report/:report_id/key-finding/:key_finding_id' => \&demo => 'key_finding');
    $r->get( '/role/:role_name' => \&demo => 'role');
    $r->get( '/software/:software_name' => \&demo => 'software');

    $app->plugin('debug') if $app->mode eq 'development';
}

1;

