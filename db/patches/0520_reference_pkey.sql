alter table reference add column publication_id
    integer references publication(id) on delete cascade;

update reference set publication_id=(select id from publication
    where publication_type_identifier='report' and fk->'identifier' = 'nca3draft');

alter table reference alter column publication_id set not null;

alter table reference
    add unique (identifier,publication_id);

alter table publication_map add unique (reference_identifier, parent);

alter table publication_map drop constraint publication_map_reference_identifier_key
