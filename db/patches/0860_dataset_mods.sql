alter table dataset add column variables varchar;

alter table dataset add column start_time timestamp;
alter table dataset add column end_time timestamp;
alter table dataset add column lat_min decimal;
alter table dataset add column lat_max decimal;
alter table dataset add column lon_min decimal;
alter table dataset add column lon_max decimal;

insert into role_type (identifier, label) values ('funding_agency', 'Funding Agency');
insert into role_type (identifier, label) values ('distributor', 'Distributor');
insert into role_type (identifier, label) values ('host', 'Host');

