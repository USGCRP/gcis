alter table report add column publication_year integer;
alter table report add constraint ck_report_pubyear check (publication_year > 0 and publication_year < 9999);

update report g
    set publication_year = (r.attrs->'Year')::integer
from
    publication p inner join reference r on r.child_publication_id = p.id
    where p.publication_type_identifier='report' and p.fk->'identifier' = g.identifier
    and r.attrs->'Year' similar to '[0-9]+';

