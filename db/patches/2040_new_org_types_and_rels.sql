/* orgs */
insert into organization_type (identifier)
values
 ('federally funded research and development center'),
 ('non-profit'),
 ('professional society/organization'),
 ('foundation'),
 ('consortium');

/* rels */
insert into organization_relationship (identifier, label)
values
 ('managed_by','managed by'),
 ('operated_by','operated by');

