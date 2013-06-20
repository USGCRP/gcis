
alter table dataset_organization drop column organization_id;
alter table contributor drop column organization_id;

alter table submitter drop column organization_id;

alter table submitter add column contributor_id integer references contributor(id);

drop table org_academic      ;
drop table org_commercial    ;
drop table org_government    ;
drop table org_ngo           ;
drop table org_project       ;
drop table org_research      ;
drop table organization      ;
drop table organization_type ;

create table organization (
    identifier varchar not null primary key,
    name varchar,
    url varchar,
    country varchar
);

create table organization_type (
    identifier varchar not null primary key
);

create table organization_type_map (
    organization varchar references organization(identifier) on delete cascade,
    organization_type varchar references organization_type(identifier) on delete cascade,
    primary key (organization, organization_type)
);

alter table contributor add column organization varchar references organization(identifier);
alter table dataset_organization add column organization varchar references organization(identifier);
