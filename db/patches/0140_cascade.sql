alter table finding_keyword_map
    drop constraint finding_keyword_map_finding_fkey,
     add constraint finding_keyword_map_finding_fkey foreign key (finding)
         references finding(identifier) on delete cascade;

alter table finding_keyword_map
    drop constraint finding_keyword_map_keyword_fkey,
     add constraint finding_keyword_map_keyword_fkey foreign key (keyword)
         references keyword(id) on delete cascade;

alter table dataset_organization_map
   drop constraint dataset_organization_ibfk_1,
    add constraint dataset_organization_ibfk_1 foreign key (dataset)
        references dataset(identifier) on delete cascade;

alter table dataset_organization_map
   drop constraint dataset_organization_organization_fkey,
    add constraint dataset_organization_organization_fkey foreign key (organization)
        references organization(identifier) on delete cascade;


