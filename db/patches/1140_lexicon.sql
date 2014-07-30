
create table exterm (
    term     varchar not null,   /* the identifier */
    context  varchar not null,   /* category of term : Agency, Collection, Platform */
    lexicon  varchar not null,   /* echo, ceos, podaac */
    gcid     varchar not null,
    primary key (lexicon, context, term),
    CHECK (lexicon similar to '[a-z0-9_-]+')
);

comment on table exterm is 'Map terms in external lexicons to GCIDs.';

select audit.audit_table('exterm');

