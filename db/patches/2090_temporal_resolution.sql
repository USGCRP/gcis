alter table dataset add column temporal_resolution varchar;
comment on column dataset.temporal_resolution is 'The temporal resolution (daily, monthly, etc.).';

