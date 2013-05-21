alter table journal alter column short_name set data type varchar;

alter table journal rename short_name to identifier;
