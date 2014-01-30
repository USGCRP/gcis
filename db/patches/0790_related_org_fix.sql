alter table organization_map drop constraint organization_map_organization_identifier_fkey,
    add constraint organization_map_organization_identifier_fkey foreign key (organization_identifier)
        references organization(identifier) on update cascade on delete cascade;

alter table organization_map drop constraint organization_map_other_organization_identifier_fkey,
    add constraint organization_map_other_organization_identifier_fkey foreign key (other_organization_identifier)
        references organization(identifier) on update cascade on delete cascade;

select audit.audit_table('organization_map');

select audit.audit_table('organization_relationship');



