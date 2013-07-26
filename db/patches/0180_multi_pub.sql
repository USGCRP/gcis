create table publication_map (
    child integer references publication(id) on delete cascade not null,
    relationship varchar not null,
    parent integer references publication(id) on delete cascade not null,
    primary key (child, relationship, parent)
);


alter table publication drop column parent_id;
alter table publication drop column fk;
alter table publication drop column parent_rel;
alter table publication add column fk hstore;
alter table publication add constraint publication_type_fk unique(publication_type,fk);

