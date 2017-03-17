ALTER TABLE figure ADD COLUMN _origination json;
COMMENT ON COLUMN figure._origination IS 'origination metadata collected by TSU, should eventually be mapped to an Activity';

