ALTER TABLE chapter ALTER COLUMN number SET DATA TYPE varchar(3);
COMMENT ON COLUMN gcis_metadata.chapter.number IS 'The alphanumeric chapter number.';
