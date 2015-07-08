alter table image add column url varchar unique;

comment on column image.url is 'A landing page for this image.';

