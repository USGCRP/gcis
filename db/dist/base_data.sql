--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


--
-- Data for Name: report_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY report_type (identifier) FROM stdin;
report
workshop_report
conference_paper
\.


--
-- Data for Name: report; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY report (identifier, title, url, doi, _public, report_type_identifier, summary, frequency, publication_year, topic, in_library, contact_note, contact_email) FROM stdin;
\.


--
-- Data for Name: _report_editor; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY _report_editor (report, username) FROM stdin;
\.


--
-- Data for Name: _report_viewer; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY _report_viewer (report, username) FROM stdin;
\.


--
-- Data for Name: activity; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY activity (identifier, data_usage, methodology, start_time, end_time, duration, computing_environment, output_artifacts, software, visualization_software, notes) FROM stdin;
\.


--
-- Data for Name: array; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY "array" (identifier, rows_in_header, rows) FROM stdin;
\.


--
-- Data for Name: chapter; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY chapter (identifier, title, report_identifier, number, url, sort_key, doi) FROM stdin;
\.


--
-- Data for Name: table; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY "table" (identifier, report_identifier, chapter_identifier, ordinal, title, caption, url) FROM stdin;
\.


--
-- Data for Name: array_table_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY array_table_map (array_identifier, table_identifier, report_identifier) FROM stdin;
\.


--
-- Data for Name: journal; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY journal (identifier, title, publisher, country, url, notes, print_issn, online_issn) FROM stdin;
\.


--
-- Data for Name: article; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY article (identifier, title, doi, year, journal_identifier, journal_vol, journal_pages, url, notes) FROM stdin;
\.


--
-- Data for Name: book; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY book (identifier, title, isbn, year, publisher, number_of_pages, url, in_library, topic) FROM stdin;
\.


--
-- Data for Name: lexicon; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY lexicon (identifier, description, url) FROM stdin;
ceos	Committee on Earth Observation Satellites	http://database.eohandbook.com
podaac	Physical Oceanography DAAC	http://podaac.jpl.nasa.gov
echo	Earth Observing System Clearing House	http://reverb.echo.nasa.gov
gcmd	Global Change Master Directory	http://gcmd.nasa.gov
\.


--
-- Data for Name: context; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY context (lexicon_identifier, identifier, version, description, url) FROM stdin;
\.


--
-- Data for Name: country; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY country (code, name) FROM stdin;
\.


--
-- Data for Name: organization_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization_type (identifier) FROM stdin;
federally funded research and development center
non-profit
professional society/organization
foundation
consortium
\.


--
-- Data for Name: organization; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization (identifier, name, url, country_code, organization_type_identifier) FROM stdin;
\.


--
-- Data for Name: person; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY person (id, url, orcid, first_name, last_name, middle_name) FROM stdin;
\.


--
-- Data for Name: role_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY role_type (identifier, label, sort_key, comment) FROM stdin;
engineer	Engineer	190	\N
manager	Manager	200	\N
\.


--
-- Data for Name: contributor; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY contributor (id, person_id, role_type_identifier, organization_identifier) FROM stdin;
\.


--
-- Name: contributor_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('contributor_id_seq', 1, false);


--
-- Data for Name: dataset; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY dataset (identifier, name, type, version, description, native_id, access_dt, url, data_qualifier, scale, spatial_ref_sys, cite_metadata, scope, spatial_extent, temporal_extent, vertical_extent, processing_level, spatial_res, doi, release_dt, publication_year, attributes, variables, start_time, end_time, lat_min, lat_max, lon_min, lon_max, description_attribution, temporal_resolution) FROM stdin;
\.


--
-- Data for Name: exterm; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY exterm (term, context, lexicon_identifier, gcid) FROM stdin;
\.


--
-- Data for Name: figure; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY figure (identifier, chapter_identifier, title, caption, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, usage_limits, submission_dt, create_dt, source_citation, ordinal, report_identifier, url) FROM stdin;
\.


--
-- Data for Name: file; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY file (file, identifier, thumbnail, mime_type, sha1, size, location, landing_page) FROM stdin;
\.


--
-- Name: file_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('file_id_seq', 1, false);


--
-- Data for Name: finding; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY finding (identifier, chapter_identifier, statement, ordinal, report_identifier, process, evidence, uncertainties, confidence, url) FROM stdin;
\.


--
-- Data for Name: gcmd_keyword; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcmd_keyword (identifier, parent_identifier, label, definition) FROM stdin;
\.


--
-- Data for Name: generic; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY generic (identifier, attrs) FROM stdin;
\.


--
-- Data for Name: image; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY image (identifier, "position", title, description, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, usage_limits, submission_dt, create_dt, url) FROM stdin;
\.


--
-- Data for Name: image_figure_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY image_figure_map (image_identifier, figure_identifier, report_identifier) FROM stdin;
\.


--
-- Data for Name: instrument; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY instrument (identifier, name, description, description_attribution) FROM stdin;
\.


--
-- Data for Name: platform_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY platform_type (identifier) FROM stdin;
spacecraft
aircraft
\.


--
-- Data for Name: platform; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY platform (identifier, name, description, url, platform_type_identifier, description_attribution, start_date, end_date) FROM stdin;
\.


--
-- Data for Name: instrument_instance; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY instrument_instance (platform_identifier, instrument_identifier, location) FROM stdin;
\.


--
-- Data for Name: instrument_measurement; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY instrument_measurement (platform_identifier, instrument_identifier, dataset_identifier) FROM stdin;
\.


--
-- Data for Name: publication_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_type (identifier, "table") FROM stdin;
platform	platform
instrument	instrument
model	model
scenario	scenario
\.


--
-- Data for Name: publication; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication (id, publication_type_identifier, fk) FROM stdin;
\.


--
-- Data for Name: methodology; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY methodology (activity_identifier, publication_id) FROM stdin;
\.


--
-- Data for Name: project; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY project (identifier, name, description, description_attribution, website) FROM stdin;
\.


--
-- Data for Name: model; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY model (identifier, project_identifier, name, version, reference_url, website, description, description_attribution) FROM stdin;
\.


--
-- Data for Name: scenario; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY scenario (identifier, name, description, description_attribution) FROM stdin;
\.


--
-- Data for Name: model_run; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY model_run (identifier, doi, model_identifier, scenario_identifier, spatial_resolution, range_start, range_end, sequence, sequence_description, activity_identifier, project_identifier, time_resolution) FROM stdin;
\.


--
-- Data for Name: organization_relationship; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization_relationship (identifier, label) FROM stdin;
managed_by	managed by
operated_by	operated by
\.


--
-- Data for Name: organization_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization_map (organization_identifier, other_organization_identifier, organization_relationship_identifier) FROM stdin;
\.


--
-- Name: person_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('person_id_seq', 1, false);


--
-- Data for Name: reference; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY reference (identifier, attrs, child_publication_id) FROM stdin;
\.


--
-- Data for Name: publication_contributor_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_contributor_map (publication_id, contributor_id, reference_identifier, sort_key) FROM stdin;
\.


--
-- Data for Name: publication_file_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_file_map (publication_id, file_identifier) FROM stdin;
\.


--
-- Data for Name: publication_gcmd_keyword_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_gcmd_keyword_map (publication_id, gcmd_keyword_identifier) FROM stdin;
\.


--
-- Name: publication_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('publication_id_seq', 1, false);


--
-- Data for Name: publication_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_map (child, relationship, parent, note, activity_identifier) FROM stdin;
\.


--
-- Data for Name: publication_reference_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_reference_map (publication_id, reference_identifier) FROM stdin;
\.


--
-- Data for Name: region; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY region (identifier, label, description) FROM stdin;
\.


--
-- Data for Name: publication_region_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_region_map (publication_id, region_identifier) FROM stdin;
\.


--
-- Data for Name: relationship; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY relationship (relationship, description) FROM stdin;
owl:sameAs	An alias
\.


--
-- Data for Name: term; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY term (identifier, lexicon_identifier, context_identifier, context_version, term, is_root, description, url) FROM stdin;
\.


--
-- Data for Name: term_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY term_map (term_identifier, relationship, gcid, description, "timestamp") FROM stdin;
\.


--
-- Data for Name: term_rel; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY term_rel (term_subject, relationship, term_object) FROM stdin;
\.


--
-- Data for Name: webpage; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY webpage (identifier, url, title, access_date) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

