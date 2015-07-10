create or replace function name_hash(first_name text, last_name text) returns varchar as $$
BEGIN
return 
    concat(
        regexp_replace(lower(first_name),'\W','','g'),
        regexp_replace(lower(last_name),'\W','','g')
    );
END; $$ LANGUAGE plpgsql immutable;

create or replace function name_unique_hash(first_name text, last_name text, orcid text) returns varchar as $$
BEGIN
return concat( name_hash(first_name, last_name), orcid );
END; $$ LANGUAGE plpgsql immutable;

create unique index uk_person_names on person( name_unique_hash(first_name, last_name, orcid) );

create index person_names on person( name_hash(first_name, last_name) );

