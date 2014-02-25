alter table dataset
    add column release_dt timestamp,
    drop column publication_dt,
    add column publication_year integer,
    add column attributes varchar;

alter table dataset add constraint ck_year
check (publication_year > 1800 and publication_year < 9999);

