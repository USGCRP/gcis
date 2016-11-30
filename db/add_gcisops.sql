CREATE USER gcisops WITH SUPERUSER PASSWORD 'gcisops';
alter role bduggan set search_path to pg_catalog, gcis_metadata, audit, public;
