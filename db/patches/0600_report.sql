delete from report where identifier='ierhplcmpsc';

delete from report where identifier='facrnpriccatf';

update report set url='http://www.nap.edu/catalog.php?record_id=12904' where identifier='oansmcco';

update report set url='http://www.nap.edu/catalog.php?record_id=12996' where identifier='fccrrtwoksbs';

alter table report add unique(url);

