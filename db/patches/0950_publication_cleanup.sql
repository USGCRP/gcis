
delete from report where identifier in (
    select g.identifier from report g
    inner join publication p on p.publication_type_identifier='report' and p.fk->'identifier' = g.identifier
    left join reference r on r.child_publication_id = p.id
    left join methodology m on m.publication_id = p.id
    where r.identifier is null and m.publication_id is null
    and g.identifier != 'nca3' and g.identifier != 'nca3draft'
);

delete from webpage where identifier in (
    select g.identifier from webpage g
    inner join publication p on p.publication_type_identifier='webpage' and p.fk->'identifier' = g.identifier
    left join reference r on r.child_publication_id = p.id
    left join methodology m on m.publication_id = p.id
    where r.identifier is null and m.publication_id is null
);

delete from book where identifier in (
    select g.identifier from book g
    inner join publication p on p.publication_type_identifier='book' and p.fk->'identifier' = g.identifier
    left join reference r on r.child_publication_id = p.id
    left join methodology m on m.publication_id = p.id
    where r.identifier is null and m.publication_id is null
);

delete from article where identifier in (
    select g.identifier from article g
    inner join publication p on p.publication_type_identifier='article' and p.fk->'identifier' = g.identifier
    left join reference r on r.child_publication_id = p.id
    left join methodology m on m.publication_id = p.id
    where r.identifier is null and m.publication_id is null
);

delete from image where identifier in (
    select identifier from image i
    left join image_figure_map f
    on f.image_identifier = i.identifier
    where f.image_identifier is null
);

