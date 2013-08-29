alter table file alter column image drop not null;

create table publication_file_map (
    publication integer references publication(id),
    file integer references file(identifier),
    primary key (publication,file)
);

