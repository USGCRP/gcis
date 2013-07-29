alter table report add column url varchar;
alter table report add column organization varchar references organization(identifier);
alter table report add column doi varchar;
update report set url='http://ncadac.globalchange.gov/download/NCAJan11-2013-publicreviewdraft-fulldraft.pdf' where identifier='nca3draft';

