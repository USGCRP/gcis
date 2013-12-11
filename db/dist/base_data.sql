--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


--
-- Data for Name: organization; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization (identifier, name, url, country) FROM stdin;
\.


--
-- Data for Name: report; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY report (identifier, title, url, organization_identifier, doi, _public) FROM stdin;
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
-- Data for Name: array; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY "array" (identifier, rows_in_header, rows) FROM stdin;
\.


--
-- Data for Name: chapter; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY chapter (identifier, title, report_identifier, number, url) FROM stdin;
\.


--
-- Data for Name: table; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY "table" (identifier, report_identifier, chapter_identifier, ordinal, title, caption) FROM stdin;
\.


--
-- Data for Name: array_table_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY array_table_map (array_identifier, table_identifier, report_identifier) FROM stdin;
\.


--
-- Data for Name: journal; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY journal (identifier, title, print_issn, online_issn, publisher, country, url, notes) FROM stdin;
\.


--
-- Data for Name: article; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY article (identifier, title, doi, year, journal_identifier, journal_vol, journal_pages, url, notes) FROM stdin;
\.


--
-- Data for Name: book; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY book (identifier, title, isbn, year, publisher, number_of_pages, url) FROM stdin;
\.


--
-- Data for Name: contributor_role_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY contributor_role_type (identifier, "table") FROM stdin;
\.


--
-- Data for Name: person; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY person (id, name, address, phone, email, url) FROM stdin;
\.


--
-- Data for Name: contributor; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY contributor (id, person_id, role_type, organization_identifier) FROM stdin;
\.


--
-- Name: contributor_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('contributor_id_seq', 1, false);


--
-- Data for Name: dataset; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY dataset (identifier, name, type, version, description, native_id, publication_dt, access_dt, url, data_qualifier, scale, spatial_ref_sys, cite_metadata, scope, spatial_extent, temporal_extent, vertical_extent, processing_level, spatial_res, doi) FROM stdin;
\.


--
-- Data for Name: dataset_lineage; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY dataset_lineage (id, dataset_id, parent_id) FROM stdin;
\.


--
-- Name: dataset_lineage_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('dataset_lineage_id_seq', 1, false);


--
-- Data for Name: dataset_organization_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY dataset_organization_map (dataset_identifier, organization_identifier) FROM stdin;
\.


--
-- Data for Name: figure; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY figure (identifier, chapter_identifier, title, caption, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, usage_limits, submission_dt, create_dt, source_citation, ordinal, report_identifier) FROM stdin;
\.


--
-- Data for Name: file; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY file (file_type, dir, file, identifier) FROM stdin;
\.


--
-- Name: file_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('file_id_seq', 1, false);


--
-- Data for Name: finding; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY finding (identifier, chapter_identifier, statement, ordinal, report_identifier, process, evidence, uncertainties, confidence) FROM stdin;
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

COPY image (identifier, "position", title, description, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, usage_limits, submission_dt, create_dt) FROM stdin;
\.


--
-- Data for Name: image_figure_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY image_figure_map (image_identifier, figure_identifier, report_identifier) FROM stdin;
\.


--
-- Data for Name: organization_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization_type (identifier) FROM stdin;
\.


--
-- Data for Name: organization_type_map; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization_type_map (organization_identifier, organization_type_identifier) FROM stdin;
\.


--
-- Name: person_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('person_id_seq', 1, false);


--
-- Data for Name: publication_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_type (identifier, "table") FROM stdin;
webpage	webpage
book	book
\.


--
-- Data for Name: publication; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication (id, publication_type_identifier, fk) FROM stdin;
\.


--
-- Data for Name: publication_contributor; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_contributor (id, publication_id, contributor_id) FROM stdin;
\.


--
-- Name: publication_contributor_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('publication_contributor_id_seq', 1, false);


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

COPY publication_map (child, relationship, parent, note) FROM stdin;
\.


--
-- Data for Name: ref_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY ref_type (identifier, "table") FROM stdin;
\.


--
-- Data for Name: publication_ref; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_ref (id, publication_id, type, fk) FROM stdin;
\.


--
-- Name: publication_ref_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('publication_ref_id_seq', 1, false);


--
-- Data for Name: reference; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY reference (identifier, attrs, publication_id, child_publication_id) FROM stdin;
\.


--
-- Data for Name: submitter; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY submitter (id, person_id, "table", fk, contributor_id) FROM stdin;
\.


--
-- Name: submitter_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('submitter_id_seq', 1, false);


--
-- Data for Name: subpubref; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY subpubref (publication_id, reference_identifier) FROM stdin;
\.


--
-- Data for Name: webpage; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY webpage (identifier, url, title, access_date) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

