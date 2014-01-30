create table organization_relationship (
    identifier varchar not null primary key,
    label varchar not null
);

insert into organization_relationship (identifier, label)
    values
         ('department', 'department of'),
         ('funded_by', 'funded by'),
         ('division_of', 'division of'),
         ('branch_of', 'branch of'),
         ('affiliated_with', 'affiliated with');

create table organization_map (
    organization_identifier varchar references organization(identifier) not null,
    other_organization_identifier varchar references organization(identifier) not null,
    organization_relationship_identifier varchar references organization_relationship(identifier) not null,
    primary key (organization_identifier, other_organization_identifier, organization_relationship_identifier)
);

