--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


--
-- Data for Name: journal; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY journal (id, identifier, title, print_issn, online_issn, publisher, country, url, notes) FROM stdin;
\.


--
-- Data for Name: article; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY article (id, short_name, title, doi, year, journal_id, journal_vol, journal_pages, url, notes) FROM stdin;
\.


--
-- Name: article_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('article_id_seq', 1, false);


--
-- Data for Name: report; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY report (title, identifier) FROM stdin;
\.


--
-- Data for Name: chapter; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY chapter (title, number, identifier, report) FROM stdin;
\.


--
-- Data for Name: contributor_role_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY contributor_role_type (id, name, "table") FROM stdin;
\.


--
-- Data for Name: organization_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization_type (id, name, "table") FROM stdin;
\.


--
-- Data for Name: organization; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization (id, organization_type, fk) FROM stdin;
\.


--
-- Data for Name: person; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY person (id, name, address, phone, email, url) FROM stdin;
\.


--
-- Data for Name: contributor; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY contributor (id, person_id, organization_id, role_type_id) FROM stdin;
\.


--
-- Name: contributor_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('contributor_id_seq', 1, false);


--
-- Name: contributor_role_type_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('contributor_role_type_id_seq', 1, false);


--
-- Data for Name: dataset; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY dataset (id, name, type, version, description, native_id, publication_dt, access_dt, url, data_qualifier, scale, spatial_ref_sys, cite_metadata, scope, spatial_extent, temporal_extent, vertical_extent, processing_level, spatial_res) FROM stdin;
\.


--
-- Name: dataset_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('dataset_id_seq', 1, false);


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
-- Data for Name: dataset_organization; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY dataset_organization (id, dataset_id, organization_id) FROM stdin;
\.


--
-- Name: dataset_organization_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('dataset_organization_id_seq', 1, false);


--
-- Data for Name: figure; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY figure (title, caption, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, keywords, usage_limits, submission_dt, create_dt, source_citation, ordinal, identifier, chapter) FROM stdin;
\.


--
-- Data for Name: image; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY image ("position", title, description, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, keywords, usage_limits, submission_dt, create_dt, identifier, figure) FROM stdin;
\.


--
-- Data for Name: file; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY file (id, file_type, dir, file, image) FROM stdin;
\.


--
-- Name: file_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('file_id_seq', 1, false);


--
-- Name: journal_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('journal_id_seq', 1, false);


--
-- Data for Name: org_academic; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_academic (id, short_name, long_name, address, email, url, notes) FROM stdin;
\.


--
-- Name: org_academic_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('org_academic_id_seq', 1, false);


--
-- Data for Name: org_commercial; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_commercial (id, short_name, long_name, address, email, url, notes) FROM stdin;
\.


--
-- Name: org_commercial_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('org_commercial_id_seq', 1, false);


--
-- Data for Name: org_government; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_government (id, short_name, long_name, address, email, url, notes) FROM stdin;
\.


--
-- Name: org_government_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('org_government_id_seq', 1, false);


--
-- Data for Name: org_project; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_project (id, short_name, long_name, address, email, url, notes) FROM stdin;
\.


--
-- Name: org_project_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('org_project_id_seq', 1, false);


--
-- Name: organization_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('organization_id_seq', 1, false);


--
-- Name: organization_type_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('organization_type_id_seq', 1, false);


--
-- Name: person_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('person_id_seq', 1, false);


--
-- Data for Name: publication_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_type (id, name, "table") FROM stdin;
\.


--
-- Data for Name: publication; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication (id, parent_id, publication_type_id, fk) FROM stdin;
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
-- Name: publication_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('publication_id_seq', 1, false);


--
-- Data for Name: ref_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY ref_type (id, name, "table") FROM stdin;
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
-- Name: publication_type_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('publication_type_id_seq', 1, false);


--
-- Name: ref_type_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('ref_type_id_seq', 1, false);


--
-- Data for Name: submitter; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY submitter (id, person_id, organization_id, "table", fk) FROM stdin;
\.


--
-- Name: submitter_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('submitter_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

