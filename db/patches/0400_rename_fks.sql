
alter table chapter rename column report to report_identifier;
alter table figure rename column chapter to chapter_identifier;
alter table figure rename column report to report_identifier;
alter table image_figure_map rename column figure to figure_identifier;
alter table image_figure_map rename column report to report_identifier;
alter table image_figure_map rename column image to image_identifier;
alter table finding rename column report to report_identifier;
alter table finding rename column chapter to chapter_identifier;
alter table finding_keyword_map rename column finding to finding_identifier;
alter table finding_keyword_map rename column keyword to keyword_id;
alter table finding_keyword_map rename column report to report_identifier;
alter table article rename column journal to journal_identifier;
alter table dataset_organization_map rename column dataset to dataset_identifier;
alter table dataset_organization_map rename column organization to organization_identifier;
alter table organization_type_map rename column organization to organization_identifier;
alter table organization_type_map rename column organization_type to organization_type_identifier;
alter table contributor rename column organization to organization_identifier;

