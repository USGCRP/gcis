alter table role_type add column sort_key integer;

update role_type set sort_key=10 where identifier = 'convening_lead_author';
update role_type set sort_key=20 where identifier = 'lead_author';
update role_type set sort_key=30 where identifier = 'principal_author';
update role_type set sort_key=40 where identifier = 'primary_author';
update role_type set sort_key=50 where identifier = 'secondary_author';
update role_type set sort_key=60 where identifier = 'contributing_author';
update role_type set sort_key=70 where identifier = 'author';
update role_type set sort_key=80 where identifier = 'data_producer';
update role_type set sort_key=90 where identifier = 'data_archive';
update role_type set sort_key=100 where identifier = 'funding_agency';
update role_type set sort_key=110 where identifier = 'distributor';
update role_type set sort_key=120 where identifier = 'host';
