drop table if exists publication_file_map;

create table publication_file_map (
    publication integer references publication(id) on delete cascade on update cascade,
    file integer references file(identifier) on delete cascade on update cascade,
    primary key (publication,file)
);

