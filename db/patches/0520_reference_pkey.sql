alter table reference add column publication_id
    integer references publication(id) on delete cascade;

update reference set publication_id=(select id from publication
    where publication_type_identifier='report' and fk->'identifier' = 'nca3draft');

alter table reference alter column publication_id set not null;

alter table reference
    add unique (identifier,publication_id);

alter table publication_map add unique (reference_identifier, parent);

alter table publication_map drop constraint publication_map_reference_identifier_key

alter table reference add column child_publication_id integer references publication(id) on delete cascade;

alter table reference add unique (identifier,child_publication_id);

update reference r set child_publication_id = (select child from publication_map p
    where p.reference_identifier=r.identifier);

alter table publication_map drop column reference_identifier;

create table subpubref (
    publication_id integer references publication(id) not null,
    reference_identifier varchar references reference(identifier) not null,
    primary key (publication_id, reference_identifier)
)

comment on column reference.publication_id is 'Primary publication whose bibliography contains this entry';

comment on column reference.identifier is 'A globally unique identifier for this bibliographic record';

comment on column reference.attrs is 'Attributes of this bibliographic record';


