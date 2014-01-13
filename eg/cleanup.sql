delete from publication where id in (
select id from (

select p.id,p.fk,p.publication_type_identifier
    from publication p left join image i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='image'
union 
select p.id,p.fk,p.publication_type_identifier
    from publication p left join report i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='report'
union
select p.id,p.fk,p.publication_type_identifier
    from publication p left join "table" i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='table'
union
select p.id,p.fk,p.publication_type_identifier
    from publication p left join dataset i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='dataset'
union
select p.id,p.fk,p.publication_type_identifier
    from publication p left join webpage i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='webpage'
union
select p.id,p.fk,p.publication_type_identifier
    from publication p left join chapter i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='chapter'
union
select p.id,p.fk,p.publication_type_identifier
    from publication p left join article i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='article'
union
select p.id,p.fk,p.publication_type_identifier
    from publication p left join figure i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='figure'
union
select p.id,p.fk,p.publication_type_identifier
    from publication p left join journal i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='journal'
union
select p.id,p.fk,p.publication_type_identifier
    from publication p left join finding i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='finding'
union
select p.id,p.fk,p.publication_type_identifier
    from publication p left join book i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='book'
union
select p.id,p.fk,p.publication_type_identifier
    from publication p left join generic i
    on p.fk->'identifier' = i.identifier
    where i.identifier is null and p.publication_type_identifier='generic'

) x )

