alter table platform add column description_attribution varchar;
comment on column platform.description_attribution is 'A URL containing the source text of the description field.'

