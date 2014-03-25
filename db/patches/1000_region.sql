create table region (
    identifier varchar not null primary key,
    label varchar not null,
    description varchar
);

alter table region
 add constraint ck_region_identifier check (identifier similar to '[a-z0-9_-]+');

create table publication_region_map (
    publication_id integer references publication(id) on delete cascade on update cascade not null,
    region_identifier varchar references region(identifier) on delete cascade on update cascade not null,
    primary key (publication_id, region_identifier)
);

select audit.audit_table('region');
select audit.audit_table('publication_region_map');

insert into region (identifier, label, description) values ('northeast-us','Northeast','Connecticut, Delaware, District of Columbia, Maine, Maryland, Massachusetts, New Hampshire, New York, Pennsylvania, Rhode  Island, Vermont, West Virginia');
insert into region (identifier, label, description) values ('southeast-us','Southeast and Caribbean', 'Alabama, Arkansas, Florida, Georgia, Kentucky, Louisiana, Mississippi, North Carolina, Puerto Rico, Tennessee, South Carolina, U.S. Virgin Islands, Virginia');
insert into region (identifier, label, description) values ('midwest-us', 'Midwest','Illinois, Indiana, Iowa, Michigan, Minnesota, Missouri, Ohio, Wisconsin');
insert into region (identifier, label, description) values ('greatplains-us', 'Great Plains','Kansas, Montana, Nebraska, North Dakota, Oklahoma, South Dakota, Texas, Wyoming');
insert into region (identifier, label, description) values ('northwest-us', 'Northwest', 'Idaho, Oregon, Washington');
insert into region (identifier, label, description) values ('southwest-us', 'Southwest','Arizona, California, Colorado, Nevada, New Mexico, Utah');
insert into region (identifier, label, description) values ('alaska-us','Alaska','Alaska and surrounding waters');
insert into region (identifier, label, description) values ('hawaii-pacific-us', 'Hawaiʻi and U.S. Affiliated Pacific Islands',
   'Commonwealth of the Northern Mariana Islands, Federated States of Micronesia, Hawai‘i,Republic of the Marshall Islands, Republic of Palau, Territory of American Samoa, Territory of Guam');
insert into region (identifier, label ) values ('coasts-us', 'U.S. Coasts');
insert into region (identifier, label ) values ('oceans', 'Oceans');

