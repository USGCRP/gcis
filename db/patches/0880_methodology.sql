alter table activity drop column output_publication_id;

alter table activity drop column methodology_publication_id;

alter table publication_map add column activity_identifier
    varchar references activity(identifier);

create table methodology (
    activity_identifier varchar not null references activity(identifier),
    publication_id integer not null references publication(id),
    primary key (activity_identifier, publication_id)
);

