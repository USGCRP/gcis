alter table model_run drop column time_resolution;
alter table model_run add column time_resolution interval;
alter table model_run drop constraint model_run_model_identifier_scenario_identifier_spatial_reso_key;
alter table model_run add constraint model_run_unique unique (model_identifier, scenario_identifier, range_start, range_end, sequence, time_resolution);

comment on column "model_run".time_resolution is 'The temporal resolution of this run.';
