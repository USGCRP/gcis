--Rose::DB::Object does not provide native support for PostgreSQL uuid column type
--see https://groups.google.com/forum/#!topic/rose-db-object/SpGLeZLupyU

--Disable constraints
ALTER TABLE term_map DROP CONSTRAINT term_map_term_fkey; 
ALTER TABLE term_rel DROP CONSTRAINT term_rel_obj_fkey; 
ALTER TABLE term_rel DROP CONSTRAINT term_rel_subj_fkey;

--Change uuid columns to varchar
ALTER TABLE term ALTER COLUMN id TYPE character varying; 
ALTER TABLE term_map ALTER COLUMN term_id TYPE character varying; 
ALTER TABLE term_rel ALTER COLUMN term_subject TYPE character varying; 
ALTER TABLE term_rel ALTER COLUMN term_object TYPE character varying; 

--Aside: rename id to identifier, for consistency with other tables
ALTER TABLE term RENAME COLUMN id TO identifier; 
ALTER TABLE term_map RENAME COLUMN term_id TO term_identifier; 

--Re-enable constraints
ALTER TABLE term_map ADD CONSTRAINT term_map_term_fkey FOREIGN KEY (term_identifier) REFERENCES term(identifier) ON UPDATE CASCADE ON DELETE CASCADE; 
ALTER TABLE term_rel ADD CONSTRAINT term_rel_subj_fkey FOREIGN KEY (term_subject) references term(identifier) ON UPDATE CASCADE ON DELETE CASCADE; 
ALTER TABLE term_rel ADD CONSTRAINT term_rel_obj_fkey FOREIGN KEY (term_object) references term(identifier) ON UPDATE CASCADE ON DELETE CASCADE; 

--Update function for renamed field term_map.term_identifer, and refine select statement for term_map poplation
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
    INSERT INTO term_map (term_identifier, relationship, gcid)
           (SELECT t.identifier, 'owl:sameAs', NEW.gcid
            FROM term AS t
            WHERE t.term = NEW.term
              AND t.lexicon_identifier = NEW.lexicon_identifier
              AND t.context_identifier = NEW.context
           );
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

