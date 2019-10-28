CREATE ROLE dbadmin;
CREATE ROLE rdsadmin;
ALTER ROLE gcisops SET search_path TO pg_catalog, gcis_metadata, audit, public;
