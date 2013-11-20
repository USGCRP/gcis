create table gcmd_keyword (
    identifier varchar not null primary key,
    parent_identifier varchar constraint fk_parent
        references gcmd_keyword(identifier)
        deferrable initially deferred,
    label varchar,
    definition varchar
);

create view vw_gcmd_keyword as
select 
 coalesce(level4.identifier,
        level3.identifier,
        level2.identifier,
        level1.identifier,
        term.identifier,
        topic.identifier,
        category.identifier) as identifier,
 category.label as category,
 topic.label as topic,
 term.label as term,
 level1.label as level1,
 level2.label as level2,
 level3.label as level3,
 level4.label as level4
from gcmd_keyword wrapper left join gcmd_keyword category on category.parent_identifier = wrapper.identifier
    left join gcmd_keyword topic   on topic.parent_identifier = category.identifier
    left join gcmd_keyword term    on term.parent_identifier = topic.identifier
    left join gcmd_keyword level1  on level1.parent_identifier = term.identifier
    left join gcmd_keyword level2  on level2.parent_identifier = level1.identifier
    left join gcmd_keyword level3  on level3.parent_identifier = level2.identifier
    left join gcmd_keyword level4  on level4.parent_identifier = level3.identifier
where
    wrapper.identifier='1eb0ea0a-312c-4d74-8d42-6f1ad758f999' and wrapper.label='Science Keywords';

create table publication_gcmd_keyword_map (
    publication_id integer not null references publication(id) on delete cascade on update cascade,
    gcmd_keyword_identifier varchar not null references gcmd_keyword(identifier) on delete cascade on update cascade,
    primary key (publication_id, gcmd_keyword_identifier)
);

