alter table exterm add constraint exterm_gcid_check
    check (gcid similar to '[a-z0-9_/-]+');

