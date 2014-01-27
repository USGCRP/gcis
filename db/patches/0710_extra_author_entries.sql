delete from publication_contributor_map m
where 'author,'|| m.publication_id || ',' || m.contributor_id in (
    select candidate from (
        select unnest(roles) as candidate from (
            select 
                person_id,
                organization_identifier,
                array_agg(role_type_identifier || ',' || publication_id || ',' || contributor_id ) as roles
            from publication_contributor_map m
                inner join contributor c on m.contributor_id = c.id
            group by 1,2
            having count(1) > 1
                and 'author' = ANY(array_agg(role_type_identifier))
        ) x
    ) y
    where y.candidate like 'author%'
) 

