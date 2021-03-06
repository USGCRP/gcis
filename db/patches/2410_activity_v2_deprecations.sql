/* Changes to create a modern version of the Activity */

COMMENT ON COLUMN activity.duration
  IS 'DEPRECATED - use activity_duration to document the time taken to perform the activity.';
COMMENT ON COLUMN activity.data_usage
  IS 'DEPRECATED - A description of the way in which input data were used for this activity.';
COMMENT ON COLUMN activity.notes
  IS 'DEPRECATED - Other information about this activity which might be useful for traceability or reproducability.';

COMMENT ON COLUMN activity.output_artifacts
  IS 'Deprecated outside of NCO assessment activities. The final output filenames from the process.';

COMMENT ON COLUMN activity.methodology
  IS 'The process of creating the resulting object from the input, in the author’s own words and in such a way that another expert partycould reproduce the output.';
COMMENT ON COLUMN activity.visualization_software
  IS 'Primary visualization software (with version) used.';

COMMENT ON COLUMN activity.start_time
  IS 'Time bounds used to restrict the input object. Optional, depending on applicability. If equal to end_time, indicates a temporal moment.';
COMMENT ON COLUMN activity.end_time
  IS 'Time bounds used to restrict the input object. Optional, depending on applicability. If equal to start_time, indicates a temporal moment.';
