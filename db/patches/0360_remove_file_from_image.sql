/* first put into publication */

insert into publication (publication_type, fk)
select 'image',('identifier'=>f.image)::hstore from file f
left join publication p on p.publication_type='image' and (p.fk->'identifier') = f.image
where f.image is not null
and p.id is null
group by f.image;

/* then put int publication_file_map */

insert into publication_file_map
select p.id,f.identifier from file f
left join publication p on p.publication_type='image' and (p.fk->'identifier') = f.image
left join publication_file_map pf on pf.publication = p.id
where f.image is not null;

/* then remove extra column */

alter table file drop column image;

