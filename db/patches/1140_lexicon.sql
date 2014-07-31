create table lexicon (
    identifier varchar not null primary key,
    description varchar,
    url varchar,
    CHECK (identifier similar to '[a-z0-9_-]+')
);

comment on table lexicon is 'Lexicons are lists of terms external to GCIS which map to GCIDs.';

create table exterm (
    term                varchar not null,   /* the identifier */
    context             varchar not null,   /* category of term : Agency, Collection, Platform */
    lexicon_identifier  varchar not null references lexicon(identifier) on delete cascade on update cascade,
    gcid                varchar not null,
    primary key (lexicon_identifier, context, term)
);

comment on table exterm is 'Map terms in lexicons to GCIDs.';

select audit.audit_table('exterm');
select audit.audit_table('lexicon');

insert into lexicon (identifier, description, url) values ('ceos', 'Committee on Earth Observation Satellites', 'http://database.eohandbook.com');
insert into lexicon (identifier, description, url) values ('podaac', 'Physical Oceanography DAAC', 'http://podaac.jpl.nasa.gov');
insert into lexicon (identifier, description, url) values ('echo', 'Earth Observing System Clearing House', 'http://reverb.echo.nasa.gov');
insert into lexicon (identifier, description, url) values ('gcmd', 'Global Change Master Directory', 'http://gcmd.nasa.gov');

