create table activity (
    identifier varchar not null primary key,
    data_usage varchar,
    methodology varchar,
    methodology_publication_id integer references publication(id),
    start_time timestamp,
    end_time timestamp,
    duration interval,
    computing_environment varchar,
    output_artifacts varchar,
    output_publication_id integer references publication(id),
    constraint ck_activity_identifer check (identifier ~ '[a-z0-9_-]+')
);

