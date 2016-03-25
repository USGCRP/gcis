--Columns named relationship conflict with table named relationship in Rose::DB
--Renaming columns to match GCIS conventions
ALTER TABLE relationship RENAME COLUMN relationship TO identifier;
ALTER TABLE term_rel RENAME COLUMN relationship to relationship_identifier;
ALTER TABLE term_map RENAME COLUMN relationship to relationship_identifier;
