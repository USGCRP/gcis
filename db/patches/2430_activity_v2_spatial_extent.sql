/* New activity field */

ALTER TABLE activity ADD COLUMN spatial_extent json;
COMMENT ON COLUMN activity.spatial_extent IS 'Spatial bounds used to restrict the input object. GeoJSON. Optional, depending on applicability.';
