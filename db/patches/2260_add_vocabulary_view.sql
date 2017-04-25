CREATE OR REPLACE VIEW vocabulary AS SELECT * FROM lexicon;
ALTER TABLE vocabulary RENAME identifier TO lexicon_identifier;
COMMENT ON VIEW vocabulary IS 'Duplicate of lexicon, to support /vocabulary resource.';

