delete from generic where identifier not in (
    select g.identifier from generic g
    inner join publication p on p.publication_type_identifier='generic' and p.fk->'identifier' = g.identifier
    left join reference r on r.child_publication_id = p.id
    where r.identifier is not null
);

