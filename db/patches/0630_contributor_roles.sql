
drop table contributor_role_type cascade;

alter table person add orcid varchar unique;

alter table person add constraint ck_orcid check ( orcid similar to '\A\d{4}-\d{4}-\d{4}-\d{4}\Z' );

alter table person drop column email;

alter table person drop column address;

alter table person drop column phone;

alter table contributor drop constraint contributor_ibfk_1,
    add constraint contributor_ibfk_1 foreign key (person_id) references person
        on delete cascade on update cascade;

alter table contributor add constraint ck_person_org check
    ( person_id is not null or organization_identifier is not null);

delete from person;

alter table person add column first_name varchar not null;

alter table person add column last_name varchar not null;

alter table person drop column name;

alter table contributor add unique (person_id, role_type, organization_identifier);

drop table publication_contributor;

create table publication_contributor_map (
    publication_id integer not null references publication(id) on delete cascade on update cascade,
    contributor_id integer not null references contributor(id) on delete cascade on update cascade,
    primary key (publication_id, contributor_id)
);

/* alter table person add unique (first_name, last_name, ( coalesce(orcid,1))); */

create unique index uk_first_last_orcid on person (first_name, last_name, ( coalesce(orcid,'null') ) );

alter table organization
    add column organization_type_identifier varchar references organization_type(identifier) ;

update organization as o
    set organization_type_identifier
    = (select organization_type_identifier from organization_type_map m where m.organization_identifier = o.identifier);

drop table organization_type_map;

create table country (
    code varchar(2) not null primary key,
    name varchar
);

alter table organization add constraint fk_org_country
    foreign key(country) references country(code);

alter table organization rename column country to country_code;

alter table contributor
    drop constraint contributor_organization_fkey,
    add constraint contributor_organization_fkey
        foreign key (organization_identifier) references organization(identifier)
            on delete cascade on update cascade;

alter table person add column middle_name varchar;

delete from contributor where organization_identifier is null;

alter table contributor alter column organization_identifier set not null;

