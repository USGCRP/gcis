delete from contributor where id in (
    select id from contributor c left
    join publication_contributor_map m on m.contributor_id = c.id
    where m.contributor_id is null
);

