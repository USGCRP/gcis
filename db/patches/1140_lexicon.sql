create table lexicon (
    argot      varchar not null,   /* echo, ceos, podaac */
    term_class varchar not null,   /* category of term : Agency, Collection, Platform */
    term       varchar not null,   /* the identifier */
    gcid       varchar not null,
    primary key (argot, term_class, term),
    CHECK (argot similar to '[a-z0-9_-]+')
);

comment on table lexicon is 'The lexicon table has terms that map to GCIDs.';

select audit.audit_table('lexicon');

