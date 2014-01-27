alter table report drop column organization_identifier;

delete from organization where identifier not in (
select distinct(organization_identifier) from contributor c
    inner join publication_contributor_map m on m.contributor_id = c.id
    inner join publication p on m.publication_id = p.id
    inner join organization o on c.organization_identifier =o.identifier
    where fk->'report_identifier' like 'nca3%'
)

delete from contributor where id in (
    select distinct(c.id) from contributor c
    left join publication_contributor_map m on m.contributor_id = c.id
    where m.contributor_id is null
)

