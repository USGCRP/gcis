--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: gcis_metadata; Type: SCHEMA; Schema: -; Owner: -
--

-- CREATE SCHEMA gcis_metadata;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = gcis_metadata, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: article; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE article (
    identifier character varying NOT NULL,
    title character varying,
    doi character varying,
    year integer,
    journal character varying,
    journal_vol character varying,
    journal_pages character varying,
    url character varying,
    notes character varying
);


--
-- Name: chapter; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE chapter (
    identifier character varying NOT NULL,
    title character varying,
    report character varying
);


--
-- Name: contributor; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE contributor (
    id integer NOT NULL,
    person_id integer,
    organization_id integer,
    role_type character varying NOT NULL
);


--
-- Name: contributor_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contributor_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE contributor_id_seq OWNED BY contributor.id;


--
-- Name: contributor_role_type; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE contributor_role_type (
    identifier character varying NOT NULL,
    "table" character varying
);


--
-- Name: dataset; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE dataset (
    identifier character varying NOT NULL,
    name character varying,
    type character varying,
    version character varying,
    description character varying,
    native_id character varying,
    publication_dt timestamp(3) without time zone,
    access_dt timestamp(3) without time zone,
    url character varying,
    data_qualifier character varying,
    scale character varying,
    spatial_ref_sys character varying,
    cite_metadata character varying,
    scope character varying,
    spatial_extent character varying,
    temporal_extent character varying,
    vertical_extent character varying,
    processing_level character varying,
    spatial_res character varying
);


--
-- Name: dataset_lineage; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE dataset_lineage (
    id integer NOT NULL,
    dataset_id integer,
    parent_id integer
);


--
-- Name: dataset_lineage_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE dataset_lineage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dataset_lineage_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE dataset_lineage_id_seq OWNED BY dataset_lineage.id;


--
-- Name: dataset_organization; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE dataset_organization (
    identifier character varying NOT NULL,
    dataset character varying NOT NULL,
    organization_id integer NOT NULL
);


--
-- Name: figure; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE figure (
    identifier character varying NOT NULL,
    uuid character varying,
    chapter character varying,
    title character varying,
    caption character varying,
    attributes character varying,
    time_start timestamp(3) without time zone,
    time_end timestamp(3) without time zone,
    lat_max character varying,
    lat_min character varying,
    lon_max character varying,
    lon_min character varying,
    keywords character varying,
    usage_limits character varying,
    submission_dt timestamp(3) without time zone,
    create_dt timestamp(3) without time zone,
    source_citation character varying,
    ordinal integer
);


--
-- Name: file; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE file (
    identifier character varying NOT NULL,
    image character varying NOT NULL,
    file_type character varying,
    dir character varying,
    file character varying
);


--
-- Name: image; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE image (
    identifier character varying NOT NULL,
    figure character varying NOT NULL,
    "position" character varying,
    title character varying,
    description character varying,
    attributes character varying,
    time_start timestamp(3) without time zone,
    time_end timestamp(3) without time zone,
    lat_max character varying,
    lat_min character varying,
    lon_max character varying,
    lon_min character varying,
    keywords character varying,
    usage_limits character varying,
    submission_dt timestamp(3) without time zone,
    create_dt timestamp(3) without time zone
);


--
-- Name: journal; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE journal (
    identifier character varying NOT NULL,
    title character varying,
    print_issn character varying,
    online_issn character varying,
    publisher character varying,
    country character varying,
    url character varying,
    notes character varying
);


--
-- Name: org_academic; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE org_academic (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);


--
-- Name: org_commercial; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE org_commercial (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);


--
-- Name: org_government; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE org_government (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);


--
-- Name: org_ngo; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE org_ngo (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);


--
-- Name: org_project; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE org_project (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);


--
-- Name: org_research; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE org_research (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);


--
-- Name: organization; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE organization (
    id integer NOT NULL,
    organization_type character varying NOT NULL,
    fk character varying NOT NULL
);


--
-- Name: organization_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE organization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE organization_id_seq OWNED BY organization.id;


--
-- Name: organization_type; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE organization_type (
    identifier character varying NOT NULL,
    "table" character varying
);


--
-- Name: person; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE person (
    id integer NOT NULL,
    name character varying,
    address character varying,
    phone character varying,
    email character varying,
    url character varying
);


--
-- Name: person_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: person_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE person_id_seq OWNED BY person.id;


--
-- Name: publication; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE publication (
    id integer NOT NULL,
    parent_id integer,
    publication_type character varying NOT NULL,
    fk character varying NOT NULL
);


--
-- Name: publication_contributor; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE publication_contributor (
    id integer NOT NULL,
    publication_id integer,
    contributor_id integer
);


--
-- Name: publication_contributor_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE publication_contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: publication_contributor_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE publication_contributor_id_seq OWNED BY publication_contributor.id;


--
-- Name: publication_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE publication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: publication_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE publication_id_seq OWNED BY publication.id;


--
-- Name: publication_ref; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE publication_ref (
    id integer NOT NULL,
    publication_id integer,
    type character varying NOT NULL,
    fk integer NOT NULL
);


--
-- Name: publication_ref_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE publication_ref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: publication_ref_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE publication_ref_id_seq OWNED BY publication_ref.id;


--
-- Name: publication_type; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE publication_type (
    identifier character varying NOT NULL,
    "table" character varying
);


--
-- Name: ref_type; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE ref_type (
    identifier character varying NOT NULL,
    "table" character varying
);


--
-- Name: report; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE report (
    identifier character varying NOT NULL,
    title character varying
);


--
-- Name: submitter; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE submitter (
    id integer NOT NULL,
    person_id integer,
    organization_id integer,
    "table" character varying,
    fk integer
);


--
-- Name: submitter_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE submitter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submitter_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE submitter_id_seq OWNED BY submitter.id;


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY contributor ALTER COLUMN id SET DEFAULT nextval('contributor_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY dataset_lineage ALTER COLUMN id SET DEFAULT nextval('dataset_lineage_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY organization ALTER COLUMN id SET DEFAULT nextval('organization_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY person ALTER COLUMN id SET DEFAULT nextval('person_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication ALTER COLUMN id SET DEFAULT nextval('publication_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication_contributor ALTER COLUMN id SET DEFAULT nextval('publication_contributor_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication_ref ALTER COLUMN id SET DEFAULT nextval('publication_ref_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY submitter ALTER COLUMN id SET DEFAULT nextval('submitter_id_seq'::regclass);


--
-- Data for Name: article; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY article (identifier, title, doi, year, journal, journal_vol, journal_pages, url, notes) FROM stdin;
\.


--
-- Data for Name: chapter; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY chapter (identifier, title, report) FROM stdin;
\.


--
-- Data for Name: contributor; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY contributor (id, person_id, organization_id, role_type) FROM stdin;
\.


--
-- Name: contributor_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('contributor_id_seq', 1, false);


--
-- Data for Name: contributor_role_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY contributor_role_type (identifier, "table") FROM stdin;
\.


--
-- Data for Name: dataset; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY dataset (identifier, name, type, version, description, native_id, publication_dt, access_dt, url, data_qualifier, scale, spatial_ref_sys, cite_metadata, scope, spatial_extent, temporal_extent, vertical_extent, processing_level, spatial_res) FROM stdin;
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
-- Data for Name: dataset_organization; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY dataset_organization (identifier, dataset, organization_id) FROM stdin;
\.


--
-- Data for Name: figure; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY figure (identifier, uuid, chapter, title, caption, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, keywords, usage_limits, submission_dt, create_dt, source_citation, ordinal) FROM stdin;
\.


--
-- Data for Name: file; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY file (identifier, image, file_type, dir, file) FROM stdin;
\.


--
-- Data for Name: image; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY image (identifier, figure, "position", title, description, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, keywords, usage_limits, submission_dt, create_dt) FROM stdin;
\.


--
-- Data for Name: journal; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY journal (identifier, title, print_issn, online_issn, publisher, country, url, notes) FROM stdin;
\.


--
-- Data for Name: org_academic; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_academic (identifier, title, address, email, url, country, notes) FROM stdin;
\.


--
-- Data for Name: org_commercial; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_commercial (identifier, title, address, email, url, country, notes) FROM stdin;
\.


--
-- Data for Name: org_government; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_government (identifier, title, address, email, url, country, notes) FROM stdin;
\.


--
-- Data for Name: org_ngo; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_ngo (identifier, title, address, email, url, country, notes) FROM stdin;
\.


--
-- Data for Name: org_project; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_project (identifier, title, address, email, url, country, notes) FROM stdin;
\.


--
-- Data for Name: org_research; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_research (identifier, title, address, email, url, country, notes) FROM stdin;
\.


--
-- Data for Name: organization; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization (id, organization_type, fk) FROM stdin;
\.


--
-- Name: organization_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('organization_id_seq', 1, false);


--
-- Data for Name: organization_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization_type (identifier, "table") FROM stdin;
academic	org_academic
government	org_government
commercial	org_commercial
project	org_project
research	org_research
ngo	org_ngo
\.


--
-- Data for Name: person; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY person (id, name, address, phone, email, url) FROM stdin;
\.


--
-- Name: person_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('person_id_seq', 1, false);


--
-- Data for Name: publication; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication (id, parent_id, publication_type, fk) FROM stdin;
1	\N	report	1
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

SELECT pg_catalog.setval('publication_id_seq', 1, true);


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
-- Data for Name: publication_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_type (identifier, "table") FROM stdin;
journal	journal
article	article
report	report
chapter	chapter
figure	figure
\.


--
-- Data for Name: ref_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY ref_type (identifier, "table") FROM stdin;
\.


--
-- Data for Name: report; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY report (identifier, title) FROM stdin;
NCA2013	NCA2013
\.


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
-- Name: article_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY article
    ADD CONSTRAINT article_pkey PRIMARY KEY (identifier);


--
-- Name: chapter_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_pkey PRIMARY KEY (identifier);


--
-- Name: contributor_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_pkey PRIMARY KEY (id);


--
-- Name: contributor_role_type_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contributor_role_type
    ADD CONSTRAINT contributor_role_type_pkey PRIMARY KEY (identifier);


--
-- Name: dataset_lineage_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dataset_lineage
    ADD CONSTRAINT dataset_lineage_pkey PRIMARY KEY (id);


--
-- Name: dataset_organization_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_pkey PRIMARY KEY (identifier);


--
-- Name: dataset_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dataset
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (identifier);


--
-- Name: figure_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_pkey PRIMARY KEY (identifier);


--
-- Name: file_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_pkey PRIMARY KEY (identifier);


--
-- Name: image_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY image
    ADD CONSTRAINT image_pkey PRIMARY KEY (identifier);


--
-- Name: journal_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY journal
    ADD CONSTRAINT journal_pkey PRIMARY KEY (identifier);


--
-- Name: org_academic_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY org_academic
    ADD CONSTRAINT org_academic_pkey PRIMARY KEY (identifier);


--
-- Name: org_commercial_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY org_commercial
    ADD CONSTRAINT org_commercial_pkey PRIMARY KEY (identifier);


--
-- Name: org_government_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY org_government
    ADD CONSTRAINT org_government_pkey PRIMARY KEY (identifier);


--
-- Name: org_ngo_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY org_ngo
    ADD CONSTRAINT org_ngo_pkey PRIMARY KEY (identifier);


--
-- Name: org_project_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY org_project
    ADD CONSTRAINT org_project_pkey PRIMARY KEY (identifier);


--
-- Name: org_research_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY org_research
    ADD CONSTRAINT org_research_pkey PRIMARY KEY (identifier);


--
-- Name: organization_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: organization_type_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organization_type
    ADD CONSTRAINT organization_type_pkey PRIMARY KEY (identifier);


--
-- Name: person_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);


--
-- Name: publication_contributor_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_pkey PRIMARY KEY (id);


--
-- Name: publication_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_pkey PRIMARY KEY (id);


--
-- Name: publication_ref_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_pkey PRIMARY KEY (id);


--
-- Name: publication_type_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publication_type
    ADD CONSTRAINT publication_type_pkey PRIMARY KEY (identifier);


--
-- Name: ref_type_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ref_type
    ADD CONSTRAINT ref_type_pkey PRIMARY KEY (identifier);


--
-- Name: report_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY report
    ADD CONSTRAINT report_pkey PRIMARY KEY (identifier);


--
-- Name: submitter_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY submitter
    ADD CONSTRAINT submitter_pkey PRIMARY KEY (id);


--
-- Name: article_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY article
    ADD CONSTRAINT article_ibfk_1 FOREIGN KEY (journal) REFERENCES journal(identifier) MATCH FULL;


--
-- Name: chapter_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_ibfk_1 FOREIGN KEY (report) REFERENCES report(identifier) MATCH FULL;


--
-- Name: contributor_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_1 FOREIGN KEY (person_id) REFERENCES person(id) MATCH FULL;


--
-- Name: contributor_ibfk_2; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_2 FOREIGN KEY (organization_id) REFERENCES organization(id) MATCH FULL;


--
-- Name: contributor_ibfk_3; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_3 FOREIGN KEY (role_type) REFERENCES contributor_role_type(identifier) MATCH FULL;


--
-- Name: dataset_organization_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_ibfk_1 FOREIGN KEY (dataset) REFERENCES dataset(identifier) MATCH FULL;


--
-- Name: dataset_organization_ibfk_2; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_ibfk_2 FOREIGN KEY (organization_id) REFERENCES organization(id) MATCH FULL;


--
-- Name: figure_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_ibfk_1 FOREIGN KEY (chapter) REFERENCES chapter(identifier) MATCH FULL;


--
-- Name: file_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_ibfk_1 FOREIGN KEY (image) REFERENCES image(identifier) MATCH FULL;


--
-- Name: image_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY image
    ADD CONSTRAINT image_ibfk_1 FOREIGN KEY (figure) REFERENCES figure(identifier) MATCH FULL;


--
-- Name: organization_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_ibfk_1 FOREIGN KEY (organization_type) REFERENCES organization_type(identifier) MATCH FULL;


--
-- Name: publication_contributor_ibfk_2; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_ibfk_2 FOREIGN KEY (contributor_id) REFERENCES contributor(id) MATCH FULL;


--
-- Name: publication_contributor_ibfk_3; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_ibfk_3 FOREIGN KEY (publication_id) REFERENCES publication(id) MATCH FULL;


--
-- Name: publication_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_ibfk_1 FOREIGN KEY (parent_id) REFERENCES publication(id) MATCH FULL;


--
-- Name: publication_ibfk_2; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_ibfk_2 FOREIGN KEY (publication_type) REFERENCES publication_type(identifier) MATCH FULL;


--
-- Name: publication_ref_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_ibfk_1 FOREIGN KEY (type) REFERENCES ref_type(identifier) MATCH FULL;


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

-- REVOKE ALL ON SCHEMA public FROM PUBLIC;
-- REVOKE ALL ON SCHEMA public FROM postgres;
-- GRANT ALL ON SCHEMA public TO postgres;
-- GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

