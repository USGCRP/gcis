alter table finding add column process varchar;
alter table finding add column evidence varchar;
alter table finding add column uncertainties varchar;
alter table finding add column confidence varchar;
comment on column finding.evidence is 'Description of evidence base';
comment on column finding.uncertainties is 'New information and remaining uncertainties';
comment on column finding.confidence is 'Assessment of confidence based on evidence';

