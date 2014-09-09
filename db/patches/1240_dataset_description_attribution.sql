alter table dataset add column description_attribution varchar;
comment on column dataset.description_attribution is 'A URL containing the source text of the description field.';

