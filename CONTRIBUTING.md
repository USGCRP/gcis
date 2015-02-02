Contributing to the GCIS
========================

The Global Change Information System is intended to be useful to people
in a variety of roles, including data managers, policy makers, decision
makers, scientists and the general public.  If the GCIS comes close to
being useful to you and you would like to see it expanded to cover a
particular use case, or if it already is, but it could be more useful
to you or to your organization, or if you just have an idea about how
it could be made more useful to others, please consider contributing by
writing code or documentation or by participating in discussions on the
mailing lists (listed below).

The GCIS server software is distributed as open source software via
github, at <http://github.com/USGCRP/gcis>.  The USGCRP maintains
a production instance of the GCIS at <http://data.globalchange.gov>.

This guide contains both a technical overview and brief explanation
of our policies regarding contributions to server software.  Our rough
policy for incorporating contributions is as follows :

- Bug fixes with working tests which are sent as pull requests to
  github will be merged as soon as possible and released shortly thereafter
  to the production site.

- Small improvements to the JSON API which are 100% backwards compatible are
  generally very welcome; they can be sent as pull requests to github or
  requested on the gcis-dev mailing list.  Improvements with clear use cases
  and straightforward implementations mapping to the existing data model 
  are likely to be implemented and released quickly.  Unit tests should
  accompany feature requests.

- Changes to the database schema should be first discussed on the
  dev mailing list, and should be accompanied by a proposed schema patch
  (preferably in the form of a fork with an additional patch file
  in db/patches), as well as a unit test which exercises any new JSON
  endpoints associated with the schema change.

- Significant changes to the turtle templates should be accompanied
  by tests in t/011_sparql.t.  The test should exercise the change
  by pulling the new turtle template into an in-memory triple store
  and executing a SPARQL query which returns a triple which reflects
  the change.

- Minor changes to HTML/CSS are welcome as pull requests; major ones should
  first be discussed on the gcis-dev-group mailing list.

Mailing lists
=============

* gcis-dev-group
    - gcis-dev-group@usgcrp.gov
    - <https://groups.google.com/a/usgcrp.gov/forum/#!aboutgroup/gcis-dev-group>

* gcis-api-users
    - gcis-api-users-group@usgcrp.gov
    - <https://groups.google.com/a/usgcrp.gov/forum/#!aboutgroup/gcis-api-users-group>


Server Code
===========
The GCIS server architecture works like this :

1. Import :
    1. Data are ingested by sending POST requests to the JSON API or input through web forms.
    2. Authoritative data is then stored in a PostgreSQL database.
2. Export
    1. An application layer transforms the relational data in PostgreSQL into objects.
    2. The application sends the objects to templates to render HTML or Turtle.
    3. The application also generates data structures to render JSON or YAML.
    4. Turtle is transformed into equivalent RDF serializations automatically.
    5. Turtle is scraped and imported into a triple store.

Here are a few examples of these in a bit more detail :

1. Import.

    Here is a sample flow for a request which creates a report in the JSON API.

    1. The client sends a POST request to /report, with the payload { identifier : "/report/new-report" }.

    2. The file [lib/Tuba.pm](lib/Tuba.pm) has defined the routes.  The line which contains "$r->resource('report')" has
       defined a number of routes including POST "/report" (also GET "/report/:identifier" and various
       routes relating to forms.  These are all setup with "add_shortcut".  See [Mojolicious::Guides::Routing](https://metacpan.org/pod/distribution/Mojolicious/lib/Mojolicious/Guides/Routing.pod)
       This file associates this POST request with the report controller class, [Tuba::Report](lib/Tuba/Report.pm) and the method 'create'.

    3. The report controller class is [Tuba::Report](lib/Tuba/Report.pm).  This class has no 'create' method, but
       it inherits from [Tuba::Controller](lib/Tuba/Controller.pm).  Therefore, the 'create' method of [Tuba::Controller](lib/Tuba/Controller.pm) is called.

    4. [Tuba::Controller](lib/Tuba/Controller.pm) defines 'create', examines $c->req->json, and creates an object.
       The class of the object created is a [Tuba::DB::Object::Report](lib/Tuba/DB/Mixin/Object/Report.pm).  This object inherits from [Rose::DB::Object](https://metacpan.org/pod/Rose::DB::Object)
       and was defined by introspecting the database schema in [Tuba::DB::Objects](lib/Tuba/DB/Objects.pm).
       Note that all the heavy lifting is done by [Rose::DB::Object::Loader](https://metacpan.org/pod/Rose::DB::Object::Loader).
       Note also that custom methods for objects are added using a mixin from [Tuba::DB::Mixin::Object::Report](lib/Tuba/DB/Mixin/Object/Report.pm).

    5. The create method of [Tuba::Report](lib/Tuba/Report.pm) calls the save method of [Tuba::DB::Object::Report](lib/Tuba/DB/Mixin/Object/Report.pm).  This updates the information in the database.

    6. Finally, $c->respond_to in [Tuba::Report](lib/Tuba/Report.pm)::create sends JSON back to the client.

    The flow is similar for a form submission, except in this case $c->param is used for values, rather than $c->req->json.

2. Export.

    Here is a sample flow for retrieving data from the JSON API.

    1. The client sends a GET request to /report/new-report.

    2. As above, this goes to the class [Tuba::Report](lib/Tuba/Report.pm), but this time it goes to the method 'show'.

    3. The report is loaded into an object, [Tuba::DB::Object::Report](lib/Tuba/DB/Mixin/Object/Report.pm) using the primary key, and then the show method
       in the superclass ([Tuba::Controller](lib/Tuba/Controller.pm)::show) is called.

    4. [Tuba::Controller](lib/Tuba/Controller.pm)::show calls make_tree_for_show(), which in turn calls [Tuba::DB::Object::Report](lib/Tuba/DB/Mixin/Object/Report.pm)::as_tree().

    5. Since Tuba::DB::Mixin::Object::Report does not have an as_tree method, the default one in
       Tuba::DB::Object.pm is used.  This generates a data structure based on the attributes of the
       object, which correspond to the fields in the database.

    6. The object is serialized as JSON by $c->respond_to in [Tuba::Controller](lib/Tuba/Controller.pm)::show, and returned to the client.

3. Rendering HTML or Turtle.

    When a client sends a GET request for HTML or Turtle, steps 1-3 above are the same.
    After that, the template [report.html.ep](lib/Tuba/files/templates/report/object.html.ep)
    is rendered.  This flow is described in [Mojolicious::Guides::Rendering](https://metacpan.org/pod/distribution/Mojolicious/lib/Mojolicious/Guides/Rendering.pod).

    The only differences between rendering HTML and Turtle is that the form uses the templates
    ending in .html.ep, and the latter uses templates ending in .ttl.tut.

