create table finding (
    identifier varchar not null primary key,
    chapter varchar references chapter(identifier),
    statement varchar
);

