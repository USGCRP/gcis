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
from gcmd_keyword wrapper inner join gcmd_keyword category on category.parent_identifier = wrapper.identifier
    inner join gcmd_keyword topic   on topic.parent_identifier = category.identifier
    inner join gcmd_keyword term    on term.parent_identifier = topic.identifier
    inner join gcmd_keyword level1  on level1.parent_identifier = term.identifier
    inner join gcmd_keyword level2  on level2.parent_identifier = level1.identifier
    inner join gcmd_keyword level3  on level3.parent_identifier = level2.identifier
    inner join gcmd_keyword level4  on level4.parent_identifier = level3.identifier
where
    wrapper.identifier='1eb0ea0a-312c-4d74-8d42-6f1ad758f999' and wrapper.label='Science Keywords'
UNION
select 
 coalesce(
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
 NULL as level4
from gcmd_keyword wrapper inner join gcmd_keyword category on category.parent_identifier = wrapper.identifier
    inner join gcmd_keyword topic   on topic.parent_identifier = category.identifier
    inner join gcmd_keyword term    on term.parent_identifier = topic.identifier
    inner join gcmd_keyword level1  on level1.parent_identifier = term.identifier
    inner join gcmd_keyword level2  on level2.parent_identifier = level1.identifier
    inner join gcmd_keyword level3  on level3.parent_identifier = level2.identifier
where
    wrapper.identifier='1eb0ea0a-312c-4d74-8d42-6f1ad758f999' and wrapper.label='Science Keywords'
UNION
select 
 coalesce(
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
 NULL as level3,
 NULL as level4
from gcmd_keyword wrapper inner join gcmd_keyword category on category.parent_identifier = wrapper.identifier
    inner join gcmd_keyword topic   on topic.parent_identifier = category.identifier
    inner join gcmd_keyword term    on term.parent_identifier = topic.identifier
    inner join gcmd_keyword level1  on level1.parent_identifier = term.identifier
    inner join gcmd_keyword level2  on level2.parent_identifier = level1.identifier
where
    wrapper.identifier='1eb0ea0a-312c-4d74-8d42-6f1ad758f999' and wrapper.label='Science Keywords'
UNION
select 
 coalesce(
        level1.identifier,
        term.identifier,
        topic.identifier,
        category.identifier) as identifier,
 category.label as category,
 topic.label as topic,
 term.label as term,
 level1.label as level1,
NULL as level2, NULL as level3, NULL as level4
from gcmd_keyword wrapper inner join gcmd_keyword category on category.parent_identifier = wrapper.identifier
    inner join gcmd_keyword topic   on topic.parent_identifier = category.identifier
    inner join gcmd_keyword term    on term.parent_identifier = topic.identifier
    inner join gcmd_keyword level1  on level1.parent_identifier = term.identifier
where
    wrapper.identifier='1eb0ea0a-312c-4d74-8d42-6f1ad758f999' and wrapper.label='Science Keywords'
UNION
select 
 coalesce(
        term.identifier,
        topic.identifier,
        category.identifier) as identifier,
 category.label as category,
 topic.label as topic,
 term.label as term,
NULL as level1, NULL as level2, NULL as level3, NULL as level4
from gcmd_keyword wrapper inner join gcmd_keyword category on category.parent_identifier = wrapper.identifier
    inner join gcmd_keyword topic   on topic.parent_identifier = category.identifier
    inner join gcmd_keyword term    on term.parent_identifier = topic.identifier
where
    wrapper.identifier='1eb0ea0a-312c-4d74-8d42-6f1ad758f999' and wrapper.label='Science Keywords'
union
select 
 coalesce(
        topic.identifier,
        category.identifier) as identifier,
 category.label as category,
 topic.label as topic,
NULL as term, NULL as level1, NULL as level2, NULL as level3, NULL as level4
from gcmd_keyword wrapper inner join gcmd_keyword category on category.parent_identifier = wrapper.identifier
    inner join gcmd_keyword topic   on topic.parent_identifier = category.identifier
where
    wrapper.identifier='1eb0ea0a-312c-4d74-8d42-6f1ad758f999' and wrapper.label='Science Keywords'
union
select 
 coalesce( category.identifier) as identifier,
 category.label as category,
NULL as topic, NULL as term, NULL as level1, NULL as level2, NULL as level3, NULL as level4
from gcmd_keyword wrapper inner join gcmd_keyword category on category.parent_identifier = wrapper.identifier
where
    wrapper.identifier='1eb0ea0a-312c-4d74-8d42-6f1ad758f999' and wrapper.label='Science Keywords'
;
