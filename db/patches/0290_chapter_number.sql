alter table chapter drop constraint uk_number,
    add constraint uk_number_report unique(number,report);

