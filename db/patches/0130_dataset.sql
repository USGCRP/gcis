alter table dataset_organization drop column identifier;

alter table dataset_organization add primary key (dataset,organization);

alter table dataset_organization rename to dataset_organization_map;

insert into publication_type (identifier, "table") values ('dataset','dataset');

alter table publication add column parent_rel varchar;

alter table publication add constraint uk_publication_type_fk unique (publication_type, fk);

