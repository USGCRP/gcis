
SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;






CREATE FUNCTION delete_publication() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    delete from publication
         where publication_type_identifier = TG_TABLE_NAME::text and
            fk = slice(hstore(OLD.*),akeys(fk));
    RETURN OLD;
END; $$;



CREATE FUNCTION update_publication() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    update publication set fk = slice(hstore(NEW.*),akeys(fk))
         where publication_type_identifier = TG_TABLE_NAME::text and
            fk = slice(hstore(OLD.*),akeys(fk));
     RETURN NEW;
END; $$;


SET default_tablespace = '';

SET default_with_oids = false;


CREATE TABLE _report_editor (
    report character varying NOT NULL,
    username character varying NOT NULL
);



CREATE TABLE _report_viewer (
    report character varying NOT NULL,
    username character varying NOT NULL
);



CREATE TABLE "array" (
    identifier character varying NOT NULL,
    rows_in_header integer DEFAULT 0,
    rows character varying[],
    CONSTRAINT ck_array_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



CREATE TABLE array_table_map (
    array_identifier character varying NOT NULL,
    table_identifier character varying NOT NULL,
    report_identifier character varying NOT NULL
);



CREATE TABLE article (
    identifier character varying NOT NULL,
    title character varying,
    doi character varying,
    year integer,
    journal_identifier character varying NOT NULL,
    journal_vol character varying,
    journal_pages character varying,
    url character varying,
    notes character varying
);



CREATE TABLE book (
    identifier character varying NOT NULL,
    title character varying NOT NULL,
    isbn character varying,
    year numeric,
    publisher character varying,
    number_of_pages numeric,
    url character varying,
    CONSTRAINT ck_book_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



CREATE TABLE chapter (
    identifier character varying NOT NULL,
    title character varying,
    report_identifier character varying NOT NULL,
    number integer,
    url character varying,
    CONSTRAINT ck_chapter_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON COLUMN chapter.identifier IS 'A unique identifier for the chapter.';



CREATE TABLE contributor (
    id integer NOT NULL,
    person_id integer,
    role_type_identifier character varying NOT NULL,
    organization_identifier character varying NOT NULL,
    CONSTRAINT ck_person_org CHECK (((person_id IS NOT NULL) OR (organization_identifier IS NOT NULL)))
);



CREATE SEQUENCE contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE contributor_id_seq OWNED BY contributor.id;



CREATE TABLE country (
    code character varying(2) NOT NULL,
    name character varying
);



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
    spatial_res character varying,
    doi character varying
);



CREATE TABLE dataset_lineage (
    id integer NOT NULL,
    dataset_id integer,
    parent_id integer
);



CREATE SEQUENCE dataset_lineage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE dataset_lineage_id_seq OWNED BY dataset_lineage.id;



CREATE TABLE figure (
    identifier character varying NOT NULL,
    chapter_identifier character varying,
    title character varying,
    caption character varying,
    attributes character varying,
    time_start timestamp(3) without time zone,
    time_end timestamp(3) without time zone,
    lat_max character varying,
    lat_min character varying,
    lon_max character varying,
    lon_min character varying,
    usage_limits character varying,
    submission_dt timestamp(3) without time zone,
    create_dt timestamp(3) without time zone,
    source_citation character varying,
    ordinal integer,
    report_identifier character varying NOT NULL,
    CONSTRAINT ck_figure_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON COLUMN figure.identifier IS 'A unique identifier for the figure.';



COMMENT ON COLUMN figure.ordinal IS 'The numeric identifier for this figure which is not part of the chapter';



CREATE TABLE file (
    file_type character varying,
    file character varying NOT NULL,
    identifier character varying NOT NULL,
    CONSTRAINT ck_file_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



CREATE SEQUENCE file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE file_id_seq OWNED BY file.identifier;



CREATE TABLE finding (
    identifier character varying NOT NULL,
    chapter_identifier character varying,
    statement character varying,
    ordinal integer,
    report_identifier character varying NOT NULL,
    process character varying,
    evidence character varying,
    uncertainties character varying,
    confidence character varying,
    CONSTRAINT ck_finding_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON COLUMN finding.evidence IS 'Description of evidence base';



COMMENT ON COLUMN finding.uncertainties IS 'New information and remaining uncertainties';



COMMENT ON COLUMN finding.confidence IS 'Assessment of confidence based on evidence';



CREATE TABLE gcmd_keyword (
    identifier character varying NOT NULL,
    parent_identifier character varying,
    label character varying,
    definition character varying
);



CREATE TABLE generic (
    identifier character varying NOT NULL,
    attrs hstore,
    CONSTRAINT ck_generic_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



CREATE TABLE image (
    identifier character varying NOT NULL,
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
    usage_limits character varying,
    submission_dt timestamp(3) without time zone,
    create_dt timestamp(3) without time zone,
    CONSTRAINT ck_image_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON COLUMN image.identifier IS 'A unique identifier for the image.';



CREATE TABLE image_figure_map (
    image_identifier character varying NOT NULL,
    figure_identifier character varying NOT NULL,
    report_identifier character varying NOT NULL
);



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



CREATE TABLE organization (
    identifier character varying NOT NULL,
    name character varying,
    url character varying,
    country_code character varying,
    organization_type_identifier character varying
);



CREATE TABLE organization_type (
    identifier character varying NOT NULL
);



CREATE TABLE person (
    id integer NOT NULL,
    url character varying,
    orcid character varying,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    middle_name character varying,
    CONSTRAINT ck_orcid CHECK (((orcid)::text ~ similar_escape('\A\d{4}-\d{4}-\d{4}-\d{4}\Z'::text, NULL::text)))
);



CREATE SEQUENCE person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE person_id_seq OWNED BY person.id;



CREATE TABLE publication (
    id integer NOT NULL,
    publication_type_identifier character varying NOT NULL,
    fk hstore NOT NULL
);



CREATE TABLE publication_contributor_map (
    publication_id integer NOT NULL,
    contributor_id integer NOT NULL
);



CREATE TABLE publication_file_map (
    publication_id integer NOT NULL,
    file_identifier character varying NOT NULL
);



CREATE TABLE publication_gcmd_keyword_map (
    publication_id integer NOT NULL,
    gcmd_keyword_identifier character varying NOT NULL
);



CREATE SEQUENCE publication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE publication_id_seq OWNED BY publication.id;



CREATE TABLE publication_map (
    child integer NOT NULL,
    relationship character varying NOT NULL,
    parent integer NOT NULL,
    note character varying
);



CREATE TABLE publication_ref (
    id integer NOT NULL,
    publication_id integer,
    type character varying NOT NULL,
    fk integer NOT NULL
);



CREATE SEQUENCE publication_ref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE publication_ref_id_seq OWNED BY publication_ref.id;



CREATE TABLE publication_type (
    identifier character varying NOT NULL,
    "table" character varying
);



CREATE TABLE ref_type (
    identifier character varying NOT NULL,
    "table" character varying
);



CREATE TABLE reference (
    identifier character varying NOT NULL,
    attrs hstore,
    publication_id integer NOT NULL,
    child_publication_id integer,
    CONSTRAINT ck_reference_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON COLUMN reference.identifier IS 'A globally unique identifier for this bibliographic record';



COMMENT ON COLUMN reference.attrs IS 'Attributes of this bibliographic record';



COMMENT ON COLUMN reference.publication_id IS 'Primary publication whose bibliography contains this entry';



CREATE TABLE report (
    identifier character varying NOT NULL,
    title character varying,
    url character varying,
    organization_identifier character varying,
    doi character varying,
    _public boolean DEFAULT true,
    CONSTRAINT ck_report_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON COLUMN report.identifier IS 'A unique identifier for the report.';



CREATE TABLE role_type (
    identifier character varying NOT NULL,
    label character varying NOT NULL
);



CREATE TABLE submitter (
    id integer NOT NULL,
    person_id integer,
    "table" character varying,
    fk integer,
    contributor_id integer
);



CREATE SEQUENCE submitter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE submitter_id_seq OWNED BY submitter.id;



CREATE TABLE subpubref (
    publication_id integer NOT NULL,
    reference_identifier character varying NOT NULL
);



CREATE TABLE "table" (
    identifier character varying NOT NULL,
    report_identifier character varying NOT NULL,
    chapter_identifier character varying,
    ordinal integer,
    title character varying,
    caption character varying,
    CONSTRAINT ck_table_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



CREATE VIEW vw_gcmd_keyword AS
    (((((SELECT COALESCE(level4.identifier, level3.identifier, level2.identifier, level1.identifier, term.identifier, topic.identifier, category.identifier) AS identifier, category.label AS category, topic.label AS topic, term.label AS term, level1.label AS level1, level2.label AS level2, level3.label AS level3, level4.label AS level4 FROM (((((((gcmd_keyword wrapper JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text))) JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text))) JOIN gcmd_keyword term ON (((term.parent_identifier)::text = (topic.identifier)::text))) JOIN gcmd_keyword level1 ON (((level1.parent_identifier)::text = (term.identifier)::text))) JOIN gcmd_keyword level2 ON (((level2.parent_identifier)::text = (level1.identifier)::text))) JOIN gcmd_keyword level3 ON (((level3.parent_identifier)::text = (level2.identifier)::text))) JOIN gcmd_keyword level4 ON (((level4.parent_identifier)::text = (level3.identifier)::text))) WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text)) UNION SELECT COALESCE(level3.identifier, level2.identifier, level1.identifier, term.identifier, topic.identifier, category.identifier) AS identifier, category.label AS category, topic.label AS topic, term.label AS term, level1.label AS level1, level2.label AS level2, level3.label AS level3, NULL::character varying AS level4 FROM ((((((gcmd_keyword wrapper JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text))) JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text))) JOIN gcmd_keyword term ON (((term.parent_identifier)::text = (topic.identifier)::text))) JOIN gcmd_keyword level1 ON (((level1.parent_identifier)::text = (term.identifier)::text))) JOIN gcmd_keyword level2 ON (((level2.parent_identifier)::text = (level1.identifier)::text))) JOIN gcmd_keyword level3 ON (((level3.parent_identifier)::text = (level2.identifier)::text))) WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text))) UNION SELECT COALESCE(level2.identifier, level1.identifier, term.identifier, topic.identifier, category.identifier) AS identifier, category.label AS category, topic.label AS topic, term.label AS term, level1.label AS level1, level2.label AS level2, NULL::character varying AS level3, NULL::character varying AS level4 FROM (((((gcmd_keyword wrapper JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text))) JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text))) JOIN gcmd_keyword term ON (((term.parent_identifier)::text = (topic.identifier)::text))) JOIN gcmd_keyword level1 ON (((level1.parent_identifier)::text = (term.identifier)::text))) JOIN gcmd_keyword level2 ON (((level2.parent_identifier)::text = (level1.identifier)::text))) WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text))) UNION SELECT COALESCE(level1.identifier, term.identifier, topic.identifier, category.identifier) AS identifier, category.label AS category, topic.label AS topic, term.label AS term, level1.label AS level1, NULL::character varying AS level2, NULL::character varying AS level3, NULL::character varying AS level4 FROM ((((gcmd_keyword wrapper JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text))) JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text))) JOIN gcmd_keyword term ON (((term.parent_identifier)::text = (topic.identifier)::text))) JOIN gcmd_keyword level1 ON (((level1.parent_identifier)::text = (term.identifier)::text))) WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text))) UNION SELECT COALESCE(term.identifier, topic.identifier, category.identifier) AS identifier, category.label AS category, topic.label AS topic, term.label AS term, NULL::character varying AS level1, NULL::character varying AS level2, NULL::character varying AS level3, NULL::character varying AS level4 FROM (((gcmd_keyword wrapper JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text))) JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text))) JOIN gcmd_keyword term ON (((term.parent_identifier)::text = (topic.identifier)::text))) WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text))) UNION SELECT COALESCE(topic.identifier, category.identifier) AS identifier, category.label AS category, topic.label AS topic, NULL::character varying AS term, NULL::character varying AS level1, NULL::character varying AS level2, NULL::character varying AS level3, NULL::character varying AS level4 FROM ((gcmd_keyword wrapper JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text))) JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text))) WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text))) UNION SELECT COALESCE(category.identifier) AS identifier, category.label AS category, NULL::character varying AS topic, NULL::character varying AS term, NULL::character varying AS level1, NULL::character varying AS level2, NULL::character varying AS level3, NULL::character varying AS level4 FROM (gcmd_keyword wrapper JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text))) WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text));



CREATE TABLE webpage (
    identifier character varying NOT NULL,
    url character varying NOT NULL,
    title character varying,
    access_date timestamp without time zone,
    CONSTRAINT ck_webpage_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



ALTER TABLE ONLY contributor ALTER COLUMN id SET DEFAULT nextval('contributor_id_seq'::regclass);



ALTER TABLE ONLY dataset_lineage ALTER COLUMN id SET DEFAULT nextval('dataset_lineage_id_seq'::regclass);



ALTER TABLE ONLY file ALTER COLUMN identifier SET DEFAULT nextval('file_id_seq'::regclass);



ALTER TABLE ONLY person ALTER COLUMN id SET DEFAULT nextval('person_id_seq'::regclass);



ALTER TABLE ONLY publication ALTER COLUMN id SET DEFAULT nextval('publication_id_seq'::regclass);



ALTER TABLE ONLY publication_ref ALTER COLUMN id SET DEFAULT nextval('publication_ref_id_seq'::regclass);



ALTER TABLE ONLY submitter ALTER COLUMN id SET DEFAULT nextval('submitter_id_seq'::regclass);



ALTER TABLE ONLY _report_editor
    ADD CONSTRAINT _report_editor_pkey PRIMARY KEY (report, username);



ALTER TABLE ONLY _report_viewer
    ADD CONSTRAINT _report_viewer_pkey PRIMARY KEY (report, username);



ALTER TABLE ONLY "array"
    ADD CONSTRAINT array_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY array_table_map
    ADD CONSTRAINT array_table_map_pkey PRIMARY KEY (array_identifier, table_identifier, report_identifier);



ALTER TABLE ONLY article
    ADD CONSTRAINT article_doi_key UNIQUE (doi);



ALTER TABLE ONLY article
    ADD CONSTRAINT article_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY book
    ADD CONSTRAINT book_isbn_key UNIQUE (isbn);



ALTER TABLE ONLY book
    ADD CONSTRAINT book_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_pkey PRIMARY KEY (identifier, report_identifier);



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_person_id_role_type_organization_identifier_key UNIQUE (person_id, role_type_identifier, organization_identifier);



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_pkey PRIMARY KEY (id);



ALTER TABLE ONLY country
    ADD CONSTRAINT country_pkey PRIMARY KEY (code);



ALTER TABLE ONLY dataset_lineage
    ADD CONSTRAINT dataset_lineage_pkey PRIMARY KEY (id);



ALTER TABLE ONLY dataset
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_pkey PRIMARY KEY (identifier, report_identifier);



ALTER TABLE ONLY file
    ADD CONSTRAINT file_file_key UNIQUE (file);



ALTER TABLE ONLY file
    ADD CONSTRAINT file_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_pkey PRIMARY KEY (identifier, report_identifier);



ALTER TABLE ONLY gcmd_keyword
    ADD CONSTRAINT gcmd_keyword_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY generic
    ADD CONSTRAINT generic_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY image_figure_map
    ADD CONSTRAINT image_figure_map_pkey PRIMARY KEY (image_identifier, figure_identifier, report_identifier);



ALTER TABLE ONLY image
    ADD CONSTRAINT image_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY journal
    ADD CONSTRAINT journal_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_name_key UNIQUE (name);



ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY organization_type
    ADD CONSTRAINT organization_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY person
    ADD CONSTRAINT person_orcid_key UNIQUE (orcid);



ALTER TABLE ONLY person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_contributor_map
    ADD CONSTRAINT publication_contributor_map_pkey PRIMARY KEY (publication_id, contributor_id);



ALTER TABLE ONLY publication_file_map
    ADD CONSTRAINT publication_file_map_pkey PRIMARY KEY (publication_id, file_identifier);



ALTER TABLE ONLY publication_gcmd_keyword_map
    ADD CONSTRAINT publication_gcmd_keyword_map_pkey PRIMARY KEY (publication_id, gcmd_keyword_identifier);



ALTER TABLE ONLY publication_map
    ADD CONSTRAINT publication_map_pkey PRIMARY KEY (child, relationship, parent);



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_type_fk UNIQUE (publication_type_identifier, fk);



ALTER TABLE ONLY publication_type
    ADD CONSTRAINT publication_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY ref_type
    ADD CONSTRAINT ref_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY reference
    ADD CONSTRAINT reference_identifier_child_publication_id_key UNIQUE (identifier, child_publication_id);



ALTER TABLE ONLY reference
    ADD CONSTRAINT reference_identifier_publication_id_key UNIQUE (identifier, publication_id);



ALTER TABLE ONLY reference
    ADD CONSTRAINT reference_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY report
    ADD CONSTRAINT report_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY report
    ADD CONSTRAINT report_url_key UNIQUE (url);



ALTER TABLE ONLY role_type
    ADD CONSTRAINT role_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY submitter
    ADD CONSTRAINT submitter_pkey PRIMARY KEY (id);



ALTER TABLE ONLY subpubref
    ADD CONSTRAINT subpubref_pkey PRIMARY KEY (publication_id, reference_identifier);



ALTER TABLE ONLY "table"
    ADD CONSTRAINT table_pkey PRIMARY KEY (identifier, report_identifier);



ALTER TABLE ONLY journal
    ADD CONSTRAINT uk_journal_online_issn UNIQUE (online_issn);



ALTER TABLE ONLY journal
    ADD CONSTRAINT uk_journal_print_issn UNIQUE (print_issn);



ALTER TABLE ONLY chapter
    ADD CONSTRAINT uk_number_report UNIQUE (number, report_identifier);



ALTER TABLE ONLY webpage
    ADD CONSTRAINT webpage_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY webpage
    ADD CONSTRAINT webpage_url_key UNIQUE (url);



CREATE UNIQUE INDEX uk_first_last_orcid ON person USING btree (first_name, last_name, (COALESCE(orcid, 'null'::character varying)));



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON article FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON chapter FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON contributor FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON dataset FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON dataset_lineage FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON figure FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON file FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON finding FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON image FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON journal FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON person FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_ref FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_type FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON ref_type FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON report FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON submitter FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON organization FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON organization_type FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON image_figure_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON "table" FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON "array" FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON array_table_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON reference FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON subpubref FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON webpage FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON book FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_contributor_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON generic FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON article FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON chapter FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON contributor FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON dataset FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON dataset_lineage FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON figure FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON file FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON finding FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON image FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON journal FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON person FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_ref FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_type FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON ref_type FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON report FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON submitter FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON organization FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON organization_type FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON image_figure_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON "table" FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON "array" FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON array_table_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON reference FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON subpubref FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON webpage FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON book FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_contributor_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON generic FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER delpub BEFORE DELETE ON journal FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON article FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON report FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON chapter FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON figure FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON dataset FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON image FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON finding FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON generic FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON "table" FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON "array" FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON webpage FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON book FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON journal FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON article FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON report FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON chapter FOR EACH ROW WHEN ((((new.identifier)::text <> (old.identifier)::text) OR ((new.report_identifier)::text <> (old.report_identifier)::text))) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON figure FOR EACH ROW WHEN ((((new.identifier)::text <> (old.identifier)::text) OR ((new.report_identifier)::text <> (old.report_identifier)::text))) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON dataset FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON image FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON finding FOR EACH ROW WHEN ((((new.identifier)::text <> (old.identifier)::text) OR ((new.report_identifier)::text <> (old.report_identifier)::text))) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON generic FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON "array" FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON "table" FOR EACH ROW WHEN ((((new.identifier)::text <> (old.identifier)::text) OR ((new.report_identifier)::text <> (old.report_identifier)::text))) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON webpage FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON book FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



ALTER TABLE ONLY _report_editor
    ADD CONSTRAINT _report_editor_report_fkey FOREIGN KEY (report) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY _report_viewer
    ADD CONSTRAINT _report_viewer_report_fkey FOREIGN KEY (report) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY array_table_map
    ADD CONSTRAINT array_table_map_array_identifier_fkey FOREIGN KEY (array_identifier) REFERENCES "array"(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY array_table_map
    ADD CONSTRAINT array_table_map_table_identifier_fkey FOREIGN KEY (table_identifier, report_identifier) REFERENCES "table"(identifier, report_identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY article
    ADD CONSTRAINT article_ibfk_1 FOREIGN KEY (journal_identifier) REFERENCES journal(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_ibfk_1 FOREIGN KEY (report_identifier) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_1 FOREIGN KEY (person_id) REFERENCES person(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_organization_fkey FOREIGN KEY (organization_identifier) REFERENCES organization(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_chapter_report FOREIGN KEY (chapter_identifier, report_identifier) REFERENCES chapter(identifier, report_identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_report_fkey FOREIGN KEY (report_identifier) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_chapter_fkey FOREIGN KEY (chapter_identifier, report_identifier) REFERENCES chapter(identifier, report_identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_report_fkey FOREIGN KEY (report_identifier) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY organization
    ADD CONSTRAINT fk_org_country FOREIGN KEY (country_code) REFERENCES country(code);



ALTER TABLE ONLY gcmd_keyword
    ADD CONSTRAINT fk_parent FOREIGN KEY (parent_identifier) REFERENCES gcmd_keyword(identifier) DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT fk_role_type FOREIGN KEY (role_type_identifier) REFERENCES role_type(identifier);



ALTER TABLE ONLY image_figure_map
    ADD CONSTRAINT image_figure_map_figure_fkey FOREIGN KEY (figure_identifier, report_identifier) REFERENCES figure(identifier, report_identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY image_figure_map
    ADD CONSTRAINT image_figure_map_image_fkey FOREIGN KEY (image_identifier) REFERENCES image(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_organization_type_identifier_fkey FOREIGN KEY (organization_type_identifier) REFERENCES organization_type(identifier);



ALTER TABLE ONLY publication_contributor_map
    ADD CONSTRAINT publication_contributor_map_contributor_id_fkey FOREIGN KEY (contributor_id) REFERENCES contributor(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_contributor_map
    ADD CONSTRAINT publication_contributor_map_publication_id_fkey FOREIGN KEY (publication_id) REFERENCES publication(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_file_map
    ADD CONSTRAINT publication_file_map_file_identifier_fkey FOREIGN KEY (file_identifier) REFERENCES file(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_file_map
    ADD CONSTRAINT publication_file_map_publication_fkey FOREIGN KEY (publication_id) REFERENCES publication(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_gcmd_keyword_map
    ADD CONSTRAINT publication_gcmd_keyword_map_gcmd_keyword_identifier_fkey FOREIGN KEY (gcmd_keyword_identifier) REFERENCES gcmd_keyword(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_gcmd_keyword_map
    ADD CONSTRAINT publication_gcmd_keyword_map_publication_id_fkey FOREIGN KEY (publication_id) REFERENCES publication(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_ibfk_2 FOREIGN KEY (publication_type_identifier) REFERENCES publication_type(identifier) MATCH FULL;



ALTER TABLE ONLY publication_map
    ADD CONSTRAINT publication_map_child_fkey FOREIGN KEY (child) REFERENCES publication(id) ON DELETE CASCADE;



ALTER TABLE ONLY publication_map
    ADD CONSTRAINT publication_map_parent_fkey FOREIGN KEY (parent) REFERENCES publication(id) ON DELETE CASCADE;



ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_ibfk_1 FOREIGN KEY (type) REFERENCES ref_type(identifier) MATCH FULL;



ALTER TABLE ONLY reference
    ADD CONSTRAINT reference_child_publication_id_fkey FOREIGN KEY (child_publication_id) REFERENCES publication(id) ON DELETE CASCADE;



ALTER TABLE ONLY reference
    ADD CONSTRAINT reference_publication_id_fkey FOREIGN KEY (publication_id) REFERENCES publication(id) ON DELETE CASCADE;



ALTER TABLE ONLY report
    ADD CONSTRAINT report_organization_fkey FOREIGN KEY (organization_identifier) REFERENCES organization(identifier) ON UPDATE CASCADE;



ALTER TABLE ONLY submitter
    ADD CONSTRAINT submitter_contributor_id_fkey FOREIGN KEY (contributor_id) REFERENCES contributor(id);



ALTER TABLE ONLY subpubref
    ADD CONSTRAINT subpubref_publication_id_fkey FOREIGN KEY (publication_id) REFERENCES publication(id) ON DELETE CASCADE;



ALTER TABLE ONLY subpubref
    ADD CONSTRAINT subpubref_reference_identifier_fkey FOREIGN KEY (reference_identifier) REFERENCES reference(identifier) ON DELETE CASCADE;



ALTER TABLE ONLY "table"
    ADD CONSTRAINT table_chapter_identifier_fkey FOREIGN KEY (chapter_identifier, report_identifier) REFERENCES chapter(identifier, report_identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "table"
    ADD CONSTRAINT table_report_identifier_fkey FOREIGN KEY (report_identifier) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



