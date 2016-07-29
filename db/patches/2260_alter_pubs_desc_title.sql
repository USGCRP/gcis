/* Extending some publication types to have a description & title column. See github gcis#369 */

alter table article add column description character varying;
alter table webpage add column description character varying;
alter table chapter add column description character varying;


comment on column "article".description is 'The abstract of the article, or a similar brief description.';
comment on column "webpage".description is 'A brief description of the web page.';
comment on column "chapter".description is 'A brief description of the chapter.';
