alter table exterm add constraint ck_gcid check (length(gcid) > 0);

