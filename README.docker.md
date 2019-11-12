## Docker Instructions

These instructions are to get setup on any Docker-compatible machine with
the content available from the latest public content release.

The resulting instance is meant for development purposes, and should not be
used for production instances.

## Steps

  1. Install [docker](https://www.docker.com/)
  1. Install [docker compose](https://docs.docker.com/compose/install/)
  1. run `docker build -t gcis .` 
     - Go get some tea.
  1. run `mkdir -p files/assets-back`
  1. Setup postgres *alone* first
     1. If you have an existing postgres container, run `docker rm gcis_postgres_1`
     1. Download the latest [public content release](https://github.com/USGCRP/gcis/releases)
     1. Untar the files
        1. the `schema` file should be moved to `./db/docker/2_schema.sql`
        1. the `content_1` file should be moved to `./db/docker/3_content_1.sql`
        1. the `content_2` file should be moved to `./db/docker/4_content_2.sql`
           - if you want an empty GCIS instance, only copy the schema & content 1.
     1. run `docker-compose up postgres &` 
        - Refresh your tea.
     1. after the previous command finishes loading, run `docker-compose stop`
  1. Start the full docker set
     1. run `docker-compose up`
     1. GCIS should be available at `127.0.0.1` with all content available
     1. Login via the `password` option. Credentials are `docker@example.com`/`docker`
