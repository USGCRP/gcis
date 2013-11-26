create table gcmd_keyword (
    identifier varchar not null primary key,
    parent_identifier varchar constraint fk_parent
        references gcmd_keyword(identifier)
        deferrable initially deferred,
    label varchar,
    definition varchar
);

create table publication_gcmd_keyword_map (
    publication_id integer not null references publication(id) on delete cascade on update cascade,
    gcmd_keyword_identifier varchar not null references gcmd_keyword(identifier) on delete cascade on update cascade,
    primary key (publication_id, gcmd_keyword_identifier)
);

