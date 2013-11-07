alter table reference add column publication_id
    integer references publication(id) on delete cascade;

update reference set publication_id=(select id from publication
    where publication_type_identifier='report' and fk->'identifier' = 'nca3draft');

alter table reference alter column publication_id set not null;

alter table reference
    add unique (identifier,publication_id);

alter table publication_map add unique (reference_identifier, parent);

alter table publication_map drop constraint publication_map_reference_identifier_key

comment on column reference.publication_id is 'Primary publication whose bibliography contains this entry';

comment on column reference.identifier is 'A globally unique identifier for this bibliographic record';

comment on column reference.attrs is 'Attributes of this bibliographic record';
