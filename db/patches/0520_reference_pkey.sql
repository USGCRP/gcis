alter table reference add column publication_id
    integer references publication(id) on delete cascade;

update reference set publication_id=(select id from publication
    where publication_type_identifier='report' and fk->'identifier' = 'nca3draft');

alter table reference alter column publication_id set not null;

alter table publication_map drop constraint publication_map_reference_identifier_fkey;

alter table reference
    drop constraint reference_pkey,
    add primary key (identifier,publication_id);

alter table publication_map add constraint publication_map_reference
    foreign key (reference_identifier, parent) references reference(identifier,publication_id);

alter table publication_map add unique (reference_identifier, parent);

alter table reference add unique(identifier);

