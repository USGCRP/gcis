create table role_type (
    identifier varchar not null primary key,
    label varchar not null
);

insert into role_type (identifier, label)
values ('author', 'Author'),
('lead_author', 'Lead Author'),
('convening_lead_author', 'Conventing Lead Author'),
('contributing_author', 'Contributing Author');

alter table contributor rename column role_type to role_type_identifier;

alter table contributor add constraint fk_role_type foreign key
(role_type_identifier) references role_type(identifier);

