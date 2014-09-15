alter table instrument add column description_attribution varchar;
comment on column instrument.description_attribution is 'A URL containing the source text of the description field.'

