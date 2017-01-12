ALTER TABLE figure ALTER COLUMN ordinal TYPE varchar;
COMMENT ON COLUMN figure.ordinal IS 'The numeric position of this figure within a chapter. Must start with a number, may contain numbers, letters, dashes, dots and underscores';
ALTER TABLE figure ADD CONSTRAINT figure_mostly_numeric_ordinal CHECK (ordinal ~ '^[0-9]+[0-9a-zA-Z._-]*$');

ALTER TABLE finding ALTER COLUMN ordinal TYPE varchar;
COMMENT ON COLUMN finding.ordinal IS 'The numeric position of this finding within a chapter. Must start with a number, may contain numbers, letters, dashes, dots and underscores';
ALTER TABLE finding ADD CONSTRAINT finding_mostly_numeric_ordinal CHECK (ordinal ~ '^[0-9]+[0-9a-zA-Z._-]*$');

ALTER TABLE gcis_metadata.table ALTER COLUMN ordinal TYPE varchar;
COMMENT ON COLUMN gcis_metadata.table.ordinal IS 'The numeric position of this table within a chapter. Must start with a number, may contain numbers, letters, dashes, dots and underscores';
ALTER TABLE gcis_metadata.table ADD CONSTRAINT table_mostly_numeric_ordinal CHECK (ordinal ~ '^[0-9]+[0-9a-zA-Z._-]*$');

