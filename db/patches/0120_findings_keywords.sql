alter table finding add column ordinal integer;

alter table finding add column report varchar references report(identifier);

create table keyword (
    id serial not null primary key,
    category varchar not null,
    topic varchar,
    term varchar,
    level1 varchar,
    level2 varchar,
    level3 varchar,
    constraint uk_gcmd unique (category, topic, term, level1, level2, level3)
);

create table finding_keyword_map (
    finding varchar references finding(identifier),
    keyword integer references keyword(id),
    primary key (finding,keyword)
);

