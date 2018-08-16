--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.10
-- Dumped by pg_dump version 9.6.10

SET statement_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: report_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.report_type (identifier) FROM stdin;
report
workshop_report
conference_paper
\.


--
-- Data for Name: report; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.report (identifier, title, url, doi, _public, report_type_identifier, summary, frequency, publication_year, topic, in_library, contact_note, contact_email) FROM stdin;
\.


--
-- Data for Name: _report_editor; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata._report_editor (report, username) FROM stdin;
\.


--
-- Data for Name: _report_viewer; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata._report_viewer (report, username) FROM stdin;
\.


--
-- Data for Name: activity; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.activity (identifier, data_usage, methodology, start_time, end_time, duration, computing_environment, output_artifacts, software, visualization_software, notes, activity_duration, source_access_date, interim_artifacts, source_modifications, modified_source_location, visualization_methodology, methodology_citation, methodology_contact, dataset_variables, spatial_extent) FROM stdin;
\.


--
-- Data for Name: array; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata."array" (identifier, rows_in_header, rows) FROM stdin;
\.


--
-- Data for Name: chapter; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.chapter (identifier, title, report_identifier, number, url, sort_key, doi) FROM stdin;
\.


--
-- Data for Name: table; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata."table" (identifier, report_identifier, chapter_identifier, ordinal, title, caption, url) FROM stdin;
\.


--
-- Data for Name: array_table_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.array_table_map (array_identifier, table_identifier, report_identifier) FROM stdin;
\.


--
-- Data for Name: journal; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.journal (identifier, title, publisher, country, url, notes, print_issn, online_issn) FROM stdin;
\.


--
-- Data for Name: article; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.article (identifier, title, doi, year, journal_identifier, journal_vol, journal_pages, url, notes) FROM stdin;
\.


--
-- Data for Name: book; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.book (identifier, title, isbn, year, publisher, number_of_pages, url, in_library, topic) FROM stdin;
\.


--
-- Data for Name: country; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.country (code, name) FROM stdin;
\.


--
-- Data for Name: organization_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.organization_type (identifier) FROM stdin;
federally funded research and development center
non-profit
professional society/organization
foundation
consortium
public-private partnership
\.


--
-- Data for Name: organization; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.organization (identifier, name, url, country_code, organization_type_identifier, international) FROM stdin;
\.


--
-- Data for Name: person; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.person (id, url, orcid, first_name, last_name, middle_name) FROM stdin;
\.


--
-- Data for Name: role_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.role_type (identifier, label, sort_key, comment) FROM stdin;
engineer	Engineer	190	\N
manager	Manager	200	\N
\.


--
-- Data for Name: contributor; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.contributor (id, person_id, role_type_identifier, organization_identifier) FROM stdin;
\.


--
-- Name: contributor_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('gcis_metadata.contributor_id_seq', 1, false);


--
-- Data for Name: dataset; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.dataset (identifier, name, type, version, description, native_id, access_dt, url, data_qualifier, scale, spatial_ref_sys, cite_metadata, scope, spatial_extent, temporal_extent, vertical_extent, processing_level, spatial_res, doi, release_dt, publication_year, attributes, variables, start_time, end_time, lat_min, lat_max, lon_min, lon_max, description_attribution, temporal_resolution) FROM stdin;
\.


--
-- Data for Name: lexicon; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.lexicon (identifier, description, url) FROM stdin;
ceos	Committee on Earth Observation Satellites	http://database.eohandbook.com
podaac	Physical Oceanography DAAC	http://podaac.jpl.nasa.gov
echo	Earth Observing System Clearing House	http://reverb.echo.nasa.gov
gcmd	Global Change Master Directory	http://gcmd.nasa.gov
\.


--
-- Data for Name: exterm; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.exterm (term, context, lexicon_identifier, gcid) FROM stdin;
\.


--
-- Data for Name: figure; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.figure (identifier, chapter_identifier, title, caption, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, usage_limits, submission_dt, create_dt, source_citation, ordinal, report_identifier, url, _origination) FROM stdin;
\.


--
-- Data for Name: file; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.file (file, identifier, thumbnail, mime_type, sha1, size, location, landing_page) FROM stdin;
\.


--
-- Name: file_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('gcis_metadata.file_id_seq', 1, false);


--
-- Data for Name: finding; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.finding (identifier, chapter_identifier, statement, ordinal, report_identifier, process, evidence, uncertainties, confidence, url) FROM stdin;
\.


--
-- Data for Name: gcmd_keyword; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.gcmd_keyword (identifier, parent_identifier, label, definition) FROM stdin;
\.


--
-- Data for Name: generic; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.generic (identifier, attrs) FROM stdin;
\.


--
-- Data for Name: image; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.image (identifier, "position", title, description, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, usage_limits, submission_dt, create_dt, url) FROM stdin;
\.


--
-- Data for Name: image_figure_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.image_figure_map (image_identifier, figure_identifier, report_identifier) FROM stdin;
\.


--
-- Data for Name: instrument; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.instrument (identifier, name, description, description_attribution) FROM stdin;
\.


--
-- Data for Name: platform_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.platform_type (identifier) FROM stdin;
spacecraft
aircraft
\.


--
-- Data for Name: platform; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.platform (identifier, name, description, url, platform_type_identifier, description_attribution, start_date, end_date) FROM stdin;
\.


--
-- Data for Name: instrument_instance; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.instrument_instance (platform_identifier, instrument_identifier, location) FROM stdin;
\.


--
-- Data for Name: instrument_measurement; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.instrument_measurement (platform_identifier, instrument_identifier, dataset_identifier) FROM stdin;
\.


--
-- Data for Name: publication_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.publication_type (identifier, "table") FROM stdin;
platform	platform
instrument	instrument
model	model
scenario	scenario
\.


--
-- Data for Name: publication; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.publication (id, publication_type_identifier, fk) FROM stdin;
\.


--
-- Data for Name: methodology; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.methodology (activity_identifier, publication_id) FROM stdin;
\.


--
-- Data for Name: project; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.project (identifier, name, description, description_attribution, website) FROM stdin;
\.


--
-- Data for Name: model; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.model (identifier, project_identifier, name, version, reference_url, website, description, description_attribution) FROM stdin;
\.


--
-- Data for Name: scenario; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.scenario (identifier, name, description, description_attribution) FROM stdin;
\.


--
-- Data for Name: model_run; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.model_run (identifier, doi, model_identifier, scenario_identifier, spatial_resolution, range_start, range_end, sequence, sequence_description, activity_identifier, project_identifier, time_resolution) FROM stdin;
\.


--
-- Data for Name: organization_alternate_name; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.organization_alternate_name (organization_identifier, alternate_name, language, deprecated, identifier) FROM stdin;
\.


--
-- Name: organization_alternate_name_identifier_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('gcis_metadata.organization_alternate_name_identifier_seq', 1, false);


--
-- Data for Name: organization_relationship; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.organization_relationship (identifier, label) FROM stdin;
managed_by	managed by
operated_by	operated by
unit_of	unit of
center_of	center of
\.


--
-- Data for Name: organization_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.organization_map (organization_identifier, other_organization_identifier, organization_relationship_identifier) FROM stdin;
\.


--
-- Name: person_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('gcis_metadata.person_id_seq', 1, false);


--
-- Data for Name: reference; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.reference (identifier, attrs, child_publication_id) FROM stdin;
\.


--
-- Data for Name: publication_contributor_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.publication_contributor_map (publication_id, contributor_id, reference_identifier, sort_key) FROM stdin;
\.


--
-- Data for Name: publication_file_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.publication_file_map (publication_id, file_identifier) FROM stdin;
\.


--
-- Data for Name: publication_gcmd_keyword_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.publication_gcmd_keyword_map (publication_id, gcmd_keyword_identifier) FROM stdin;
\.


--
-- Name: publication_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('gcis_metadata.publication_id_seq', 1, false);


--
-- Data for Name: publication_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.publication_map (child, relationship, parent, note, activity_identifier) FROM stdin;
\.


--
-- Data for Name: publication_reference_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.publication_reference_map (publication_id, reference_identifier) FROM stdin;
\.


--
-- Data for Name: region; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.region (identifier, label, description) FROM stdin;
\.


--
-- Data for Name: publication_region_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.publication_region_map (publication_id, region_identifier) FROM stdin;
\.


--
-- Data for Name: webpage; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY gcis_metadata.webpage (identifier, url, title, access_date) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

