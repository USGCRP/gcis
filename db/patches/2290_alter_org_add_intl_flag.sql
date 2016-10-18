ALTER TABLE organization ADD COLUMN international boolean;
COMMENT ON COLUMN gcis_metadata.organization.international IS 'Flag indicating an multinational organization with HQs in multiple countries.';
COMMENT ON COLUMN gcis_metadata.organization.country_code IS 'The country with where the organization''s primary HQ is located.';
