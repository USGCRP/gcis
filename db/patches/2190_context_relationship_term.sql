-- To create tables context, term, term_map, relationship.  
-- This is envisioned to ulitimately replace the exterm table
-- -Randall Sindlinger, 2015-11-23

--also in Build.pl
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA gcis_metadata;  --for uuid_generate_* functions

CREATE TABLE context (
    lexicon_identifier character varying NOT NULL,
    identifier character varying NOT NULL,
    version character varying DEFAULT '',
    description character varying,
    url character varying,
    CONSTRAINT context_pkey PRIMARY KEY (lexicon_identifier, identifier, version),
    CONSTRAINT context_identifier_check CHECK (((identifier)::text ~ similar_escape('[a-zA-Z0-9:_-]+'::text, NULL::text))),
    CONSTRAINT context_version_check CHECK (((version)::text ~ similar_escape('[a-z0-9_\.-]*'::text, NULL::text))),
    CONSTRAINT context_lexicon_identifier_fkey FOREIGN KEY (lexicon_identifier) REFERENCES lexicon(identifier) ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON TABLE context IS 'A context is a subset of terms within a lexicon.';
COMMENT ON COLUMN context.lexicon_identifier IS 'The lexicon associated with this context.';
COMMENT ON COLUMN context.identifier IS 'A brief descriptive identifier for this context.';
COMMENT ON COLUMN context.version IS 'The version of this context (optional).';
COMMENT ON COLUMN context.description IS 'A description of the context.';
COMMENT ON COLUMN context.url IS 'A url for further information.';

CREATE TABLE term (
    id uuid default uuid_generate_v1(),
    lexicon_identifier character varying NOT NULL,
    context_identifier character varying NOT NULL,
    context_version character varying DEFAULT '',
    term character varying NOT NULL,
    is_root boolean default FALSE,
    description character varying,
    url character varying,
    CONSTRAINT term_pkey PRIMARY KEY (id),
    CONSTRAINT term_unique UNIQUE (lexicon_identifier, context_identifier, context_version, term),
    CONSTRAINT term_lexicon_context_version_fkey FOREIGN KEY (lexicon_identifier, context_identifier, context_version) REFERENCES context(lexicon_identifier, identifier, version) ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON TABLE term IS 'Terms that have a specific lexicon and context.';
COMMENT ON COLUMN term.id IS 'A globally unique identifier for this term (a UUID).';
COMMENT ON COLUMN term.lexicon_identifier IS 'The lexicon associated with this term.';
COMMENT ON COLUMN term.context_identifier IS 'The context associated with this term.';
COMMENT ON COLUMN term.context_version IS 'The version of the context associated with this term (optional).';
COMMENT ON COLUMN term.term IS 'The term itself.';
COMMENT ON COLUMN term.is_root IS 'A flag indicating the term is at the top level (eg, no broader term).';
COMMENT ON COLUMN term.description IS 'A description of the term.';
COMMENT ON COLUMN term.url IS 'A url for further information.';

CREATE TABLE relationship (
    relationship character varying NOT NULL,
    description character varying,
    CONSTRAINT relationship_pkey PRIMARY KEY (relationship)
);

COMMENT ON TABLE relationship IS 'The blessed semantic web relationships.';
COMMENT ON COLUMN relationship.relationship IS 'A fully qualified semantic web relationship.';
COMMENT ON COLUMN relationship.description IS 'A description of the relationship.';

CREATE TABLE term_map (
    term_id uuid NOT NULL,
    relationship character varying NOT NULL,
    gcid character varying NOT NULL,
    description character varying,
    timestamp timestamp(3) without time zone DEFAULT now(),
    CONSTRAINT term_map_pkey PRIMARY KEY (term_id, relationship, gcid),
    CONSTRAINT term_map_term_fkey FOREIGN KEY (term_id) REFERENCES term(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT term_map_relationship_fkey FOREIGN KEY (relationship) REFERENCES relationship(relationship) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_gcid CHECK ((length((gcid)::text) > 0))
);

COMMENT ON TABLE term_map IS 'External terms which can be mapped to GCIS identifiers via a relationship.';
COMMENT ON COLUMN term_map.term_id IS 'The term ID (UUID).';
COMMENT ON COLUMN term_map.relationship IS 'The relationship between the term and the gcid.';
COMMENT ON COLUMN term_map.gcid IS 'The GCIS identifier (URI) to which this term is mapped.';
COMMENT ON COLUMN term_map.description IS 'A description for the GCID (optional).';
COMMENT ON COLUMN term_map.timestamp IS 'The timestamp this relationship was asserted.';

CREATE TABLE term_rel (
    term_subject uuid NOT NULL,
    relationship character varying NOT NULL,
    term_object uuid NOT NULL,
    CONSTRAINT term_rel_pkey PRIMARY KEY (term_subject, relationship, term_object),
    CONSTRAINT term_rel_subj_fkey FOREIGN KEY (term_subject) references term(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT term_rel_relationship_fkey FOREIGN KEY (relationship) REFERENCES relationship(relationship) ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT term_rel_obj_fkey FOREIGN KEY (term_object) references term(id) ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON TABLE term_rel IS 'Expresses how a term is related to another term.';
COMMENT ON COLUMN term_rel.term_subject IS 'The subject term (UUID).';
COMMENT ON COLUMN term_rel.relationship IS 'The relationship of subject to object.';
COMMENT ON COLUMN term_rel.term_object IS 'The object term (UUID).';

-- add auditing triggers for all tables
SELECT audit.audit_table('context');
SELECT audit.audit_table('term');
SELECT audit.audit_table('relationship');
SELECT audit.audit_table('term_map');
SELECT audit.audit_table('term_rel');

-- since this is to replace exterm, insert existing values in exterm into the new tables (except for term_rel)
INSERT INTO context (lexicon_identifier, identifier) (select distinct lexicon_identifier, context FROM exterm);
INSERT INTO term (lexicon_identifier, context_identifier, term) (select distinct lexicon_identifier, context, term FROM exterm);
INSERT INTO relationship (relationship, description) VALUES ('owl:sameAs','An alias');
INSERT INTO term_map (term_id, relationship, gcid) (SELECT t.id, 'owl:sameAs', x.gcid 
                                                       FROM term AS t, exterm AS x
                                                       WHERE t.lexicon_identifier = x.lexicon_identifier
                                                         AND t.context_identifier = x.context
                                                         AND t.term = x.term
                                                      );

CREATE OR REPLACE FUNCTION copy_exterm_inserts_to_term() RETURNS TRIGGER AS $$
BEGIN
    --populate context
    IF NOT EXISTS (SELECT * FROM context c
                   WHERE c.identifier = NEW.context)
    THEN INSERT INTO context (lexicon_identifier, identifier, version)
                VALUES (NEW.lexicon_identifier, NEW.context, '');
    END IF;
    --populate term
    INSERT INTO term (lexicon_identifier, context_identifier, term)
           VALUES (NEW.lexicon_identifier, NEW.context, NEW.term);
    --populate term_map
    INSERT INTO term_map (term_id, relationship, gcid)
           (SELECT t.id, 'owl:sameAs', NEW.gcid
            FROM term AS t
            WHERE t.term = NEW.term
           );
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

COMMENT ON FUNCTION copy_exterm_inserts_to_term() IS $body$
Populate fields in tables 'context', 'term', and 'term_map' for new entries in
'exterm' table.
This is to keep these new tables in sync with any new data entered into exterm
during the transition to using the new tables in the perl code.
$body$;

CREATE TRIGGER copy_exterm_inserts_to_term BEFORE INSERT ON exterm
               FOR EACH ROW EXECUTE PROCEDURE copy_exterm_inserts_to_term();
