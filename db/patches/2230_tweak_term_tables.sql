--Columns named relationship conflict with table named relationship in Rose::DB
--Renaming columns to match GCIS conventions
ALTER TABLE relationship RENAME COLUMN relationship TO identifier;
ALTER TABLE term_rel RENAME COLUMN relationship to relationship_identifier;
ALTER TABLE term_map RENAME COLUMN relationship to relationship_identifier;

--Update trigger to reflect renamed column in term_map
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
    INSERT INTO term_map (term_identifier, relationship_identifier, gcid)
           (SELECT t.identifier, 'owl:sameAs', NEW.gcid
            FROM term AS t
            WHERE t.term = NEW.term
              AND t.lexicon_identifier = NEW.lexicon_identifier
              AND t.context_identifier = NEW.context
           );
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

