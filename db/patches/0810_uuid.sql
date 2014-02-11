alter table person
    drop constraint ck_orcid,
    add constraint ck_orcid check ( orcid similar to '\A\d{4}-\d{4}-\d{4}-\d{3}[0-9X]\Z' );

