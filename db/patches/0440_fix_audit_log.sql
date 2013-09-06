update audit.logged_actions set row_data = row_data || ('report_identifier'||'=>'||(row_data->'report'))::hstore where row_data ? 'report';
update audit.logged_actions set row_data = row_data - 'report'::text where row_data ? 'report';

