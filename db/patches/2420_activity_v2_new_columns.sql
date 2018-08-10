/* New activity fields */

ALTER table activity ADD COLUMN activity_duration interval;
ALTER table activity ADD COLUMN source_access_date date;
ALTER table activity ADD COLUMN interim_artifacts text;
ALTER table activity ADD COLUMN source_modifications text;
ALTER table activity ADD COLUMN modified_source_location text;
ALTER table activity ADD COLUMN visualization_methodology text;
ALTER table activity ADD COLUMN methodology_citation text;
ALTER table activity ADD COLUMN methodology_contact text;
ALTER table activity ADD COLUMN database_variables text;

COMMENT ON COLUMN activity.activity_duration
  IS 'Captures the time taken in the process to get from the source object to the final one.';
COMMENT ON COLUMN activity.source_access_date
  IS 'The date the parent resource was accessed.';
COMMENT ON COLUMN activity.interim_artifacts
  IS 'Deprecated outside of NCO assessment activities. The names of files created along the way to create the final product.';
COMMENT ON COLUMN activity.source_modifications
  IS 'A written description of modifications done to the source object.';
COMMENT ON COLUMN activity.modified_source_location
  IS 'The location of the modified source, if available.';
COMMENT ON COLUMN activity.visualization_methodology
  IS 'The process of creating the visual portion of the output object, if any and if distinguished from the main methodology.';
COMMENT ON COLUMN activity.methodology_citation
  IS 'The citation to the methodology, if it has been published.';
COMMENT ON COLUMN activity.methodology_contact
  IS 'The point of contact for the methodology, if any.';
COMMENT ON COLUMN activity.database_variables
  IS 'A list of Dataset Variables applied in this activity.';
