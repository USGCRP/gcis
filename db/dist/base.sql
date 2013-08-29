
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
         where publication_type = TG_TABLE_NAME::text and
            fk = slice(hstore(OLD.*),akeys(fk));
    RETURN OLD;
END; $$;



CREATE FUNCTION update_publication() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    update publication set fk = slice(hstore(NEW.*),akeys(fk))
         where publication_type = TG_TABLE_NAME::text and
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



CREATE TABLE chapter (
    identifier character varying NOT NULL,
    title character varying,
    report character varying NOT NULL,
    number integer,
    url character varying
);



COMMENT ON COLUMN chapter.identifier IS 'A unique identifier for the chapter.';



CREATE TABLE contributor (
    id integer NOT NULL,
    person_id integer,
    role_type character varying NOT NULL,
    organization character varying
);



CREATE SEQUENCE contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE contributor_id_seq OWNED BY contributor.id;



CREATE TABLE contributor_role_type (
    identifier character varying NOT NULL,
    "table" character varying
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
    spatial_res character varying
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



CREATE TABLE dataset_organization_map (
    dataset character varying NOT NULL,
    organization character varying NOT NULL
);



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
    ordinal integer,
    report character varying NOT NULL
);



COMMENT ON COLUMN figure.identifier IS 'A unique identifier for the figure.';



CREATE TABLE file (
    image character varying,
    file_type character varying,
    dir character varying,
    file character varying,
    identifier integer NOT NULL
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
    chapter character varying,
    statement character varying,
    ordinal integer,
    report character varying NOT NULL
);



CREATE TABLE finding_keyword_map (
    finding character varying NOT NULL,
    keyword integer NOT NULL,
    report character varying NOT NULL
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
    keywords character varying,
    usage_limits character varying,
    submission_dt timestamp(3) without time zone,
    create_dt timestamp(3) without time zone
);



COMMENT ON COLUMN image.identifier IS 'A unique identifier for the image.';



CREATE TABLE image_figure_map (
    image character varying NOT NULL,
    figure character varying NOT NULL,
    report character varying NOT NULL
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



CREATE TABLE keyword (
    id integer NOT NULL,
    category character varying NOT NULL,
    topic character varying,
    term character varying,
    level1 character varying,
    level2 character varying,
    level3 character varying
);



CREATE SEQUENCE keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE keyword_id_seq OWNED BY keyword.id;



CREATE TABLE organization (
    identifier character varying NOT NULL,
    name character varying,
    url character varying,
    country character varying
);



CREATE TABLE organization_type (
    identifier character varying NOT NULL
);



CREATE TABLE organization_type_map (
    organization character varying NOT NULL,
    organization_type character varying NOT NULL
);



CREATE TABLE person (
    id integer NOT NULL,
    name character varying,
    address character varying,
    phone character varying,
    email character varying,
    url character varying
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
    publication_type character varying NOT NULL,
    fk hstore NOT NULL
);



CREATE TABLE publication_contributor (
    id integer NOT NULL,
    publication_id integer,
    contributor_id integer
);



CREATE SEQUENCE publication_contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE publication_contributor_id_seq OWNED BY publication_contributor.id;



CREATE TABLE publication_file_map (
    publication integer NOT NULL,
    file integer NOT NULL
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



CREATE TABLE report (
    identifier character varying NOT NULL,
    title character varying,
    url character varying,
    organization character varying,
    doi character varying,
    _public boolean DEFAULT true
);



COMMENT ON COLUMN report.identifier IS 'A unique identifier for the report.';



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



ALTER TABLE ONLY contributor ALTER COLUMN id SET DEFAULT nextval('contributor_id_seq'::regclass);



ALTER TABLE ONLY dataset_lineage ALTER COLUMN id SET DEFAULT nextval('dataset_lineage_id_seq'::regclass);



ALTER TABLE ONLY file ALTER COLUMN identifier SET DEFAULT nextval('file_id_seq'::regclass);



ALTER TABLE ONLY keyword ALTER COLUMN id SET DEFAULT nextval('keyword_id_seq'::regclass);



ALTER TABLE ONLY person ALTER COLUMN id SET DEFAULT nextval('person_id_seq'::regclass);



ALTER TABLE ONLY publication ALTER COLUMN id SET DEFAULT nextval('publication_id_seq'::regclass);



ALTER TABLE ONLY publication_contributor ALTER COLUMN id SET DEFAULT nextval('publication_contributor_id_seq'::regclass);



ALTER TABLE ONLY publication_ref ALTER COLUMN id SET DEFAULT nextval('publication_ref_id_seq'::regclass);



ALTER TABLE ONLY submitter ALTER COLUMN id SET DEFAULT nextval('submitter_id_seq'::regclass);



ALTER TABLE ONLY _report_editor
    ADD CONSTRAINT _report_editor_pkey PRIMARY KEY (report, username);



ALTER TABLE ONLY _report_viewer
    ADD CONSTRAINT _report_viewer_pkey PRIMARY KEY (report, username);



ALTER TABLE ONLY article
    ADD CONSTRAINT article_doi_key UNIQUE (doi);



ALTER TABLE ONLY article
    ADD CONSTRAINT article_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_pkey PRIMARY KEY (identifier, report);



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_pkey PRIMARY KEY (id);



ALTER TABLE ONLY contributor_role_type
    ADD CONSTRAINT contributor_role_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY dataset_lineage
    ADD CONSTRAINT dataset_lineage_pkey PRIMARY KEY (id);



ALTER TABLE ONLY dataset_organization_map
    ADD CONSTRAINT dataset_organization_pkey PRIMARY KEY (dataset, organization);



ALTER TABLE ONLY dataset
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_pkey PRIMARY KEY (identifier, report);



ALTER TABLE ONLY file
    ADD CONSTRAINT file_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY finding_keyword_map
    ADD CONSTRAINT finding_keyword_map_pkey PRIMARY KEY (finding, keyword, report);



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_pkey PRIMARY KEY (identifier, report);



ALTER TABLE ONLY image_figure_map
    ADD CONSTRAINT image_figure_map_pkey PRIMARY KEY (image, figure, report);



ALTER TABLE ONLY image
    ADD CONSTRAINT image_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY journal
    ADD CONSTRAINT journal_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY keyword
    ADD CONSTRAINT keyword_pkey PRIMARY KEY (id);



ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY organization_type_map
    ADD CONSTRAINT organization_type_map_pkey PRIMARY KEY (organization, organization_type);



ALTER TABLE ONLY organization_type
    ADD CONSTRAINT organization_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_file_map
    ADD CONSTRAINT publication_file_map_pkey PRIMARY KEY (publication, file);



ALTER TABLE ONLY publication_map
    ADD CONSTRAINT publication_map_pkey PRIMARY KEY (child, relationship, parent);



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_type_fk UNIQUE (publication_type, fk);



ALTER TABLE ONLY publication_type
    ADD CONSTRAINT publication_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY ref_type
    ADD CONSTRAINT ref_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY report
    ADD CONSTRAINT report_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY submitter
    ADD CONSTRAINT submitter_pkey PRIMARY KEY (id);



ALTER TABLE ONLY keyword
    ADD CONSTRAINT uk_gcmd UNIQUE (category, topic, term, level1, level2, level3);



ALTER TABLE ONLY chapter
    ADD CONSTRAINT uk_number_report UNIQUE (number, report);



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON article FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON chapter FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON contributor FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON contributor_role_type FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON dataset FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON dataset_lineage FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON dataset_organization_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON figure FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON file FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON finding FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON image FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON journal FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON person FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_contributor FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_ref FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_type FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON ref_type FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON report FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON submitter FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON organization FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON organization_type FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON organization_type_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON keyword FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON finding_keyword_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON image_figure_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON article FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON chapter FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON contributor FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON contributor_role_type FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON dataset FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON dataset_lineage FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON dataset_organization_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON figure FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON file FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON finding FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON image FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON journal FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON person FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_contributor FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_ref FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_type FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON ref_type FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON report FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON submitter FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON organization FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON organization_type FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON organization_type_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON keyword FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON finding_keyword_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON image_figure_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER delpub BEFORE DELETE ON journal FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON article FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON report FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON chapter FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON figure FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON dataset FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON image FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON finding FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON journal FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON article FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON report FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON chapter FOR EACH ROW WHEN ((((new.identifier)::text <> (old.identifier)::text) OR ((new.report)::text <> (old.report)::text))) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON figure FOR EACH ROW WHEN ((((new.identifier)::text <> (old.identifier)::text) OR ((new.report)::text <> (old.report)::text))) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON dataset FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON image FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON finding FOR EACH ROW WHEN ((((new.identifier)::text <> (old.identifier)::text) OR ((new.report)::text <> (old.report)::text))) EXECUTE PROCEDURE update_publication();



ALTER TABLE ONLY _report_editor
    ADD CONSTRAINT _report_editor_report_fkey FOREIGN KEY (report) REFERENCES report(identifier);



ALTER TABLE ONLY _report_viewer
    ADD CONSTRAINT _report_viewer_report_fkey FOREIGN KEY (report) REFERENCES report(identifier);



ALTER TABLE ONLY article
    ADD CONSTRAINT article_ibfk_1 FOREIGN KEY (journal) REFERENCES journal(identifier) MATCH FULL;



ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_ibfk_1 FOREIGN KEY (report) REFERENCES report(identifier) MATCH FULL;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_1 FOREIGN KEY (person_id) REFERENCES person(id) MATCH FULL;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_3 FOREIGN KEY (role_type) REFERENCES contributor_role_type(identifier) MATCH FULL;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_organization_fkey FOREIGN KEY (organization) REFERENCES organization(identifier);



ALTER TABLE ONLY dataset_organization_map
    ADD CONSTRAINT dataset_organization_ibfk_1 FOREIGN KEY (dataset) REFERENCES dataset(identifier) ON DELETE CASCADE;



ALTER TABLE ONLY dataset_organization_map
    ADD CONSTRAINT dataset_organization_organization_fkey FOREIGN KEY (organization) REFERENCES organization(identifier) ON DELETE CASCADE;



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_chapter_report FOREIGN KEY (chapter, report) REFERENCES chapter(identifier, report);



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_report_fkey FOREIGN KEY (report) REFERENCES report(identifier);



ALTER TABLE ONLY file
    ADD CONSTRAINT file_image FOREIGN KEY (image) REFERENCES image(identifier) ON DELETE CASCADE;



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_chapter_report FOREIGN KEY (chapter, report) REFERENCES chapter(identifier, report);



ALTER TABLE ONLY finding_keyword_map
    ADD CONSTRAINT finding_keyword_map_finding_fkey FOREIGN KEY (finding, report) REFERENCES finding(identifier, report) ON DELETE CASCADE;



ALTER TABLE ONLY finding_keyword_map
    ADD CONSTRAINT finding_keyword_map_keyword_fkey FOREIGN KEY (keyword) REFERENCES keyword(id) ON DELETE CASCADE;



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_report_fkey FOREIGN KEY (report) REFERENCES report(identifier);



ALTER TABLE ONLY image_figure_map
    ADD CONSTRAINT image_figure_map_figure_fkey FOREIGN KEY (figure, report) REFERENCES figure(identifier, report) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY image_figure_map
    ADD CONSTRAINT image_figure_map_image_fkey FOREIGN KEY (image) REFERENCES image(identifier) ON DELETE CASCADE;



ALTER TABLE ONLY organization_type_map
    ADD CONSTRAINT organization_type_map_organization_fkey FOREIGN KEY (organization) REFERENCES organization(identifier) ON DELETE CASCADE;



ALTER TABLE ONLY organization_type_map
    ADD CONSTRAINT organization_type_map_organization_type_fkey FOREIGN KEY (organization_type) REFERENCES organization_type(identifier) ON DELETE CASCADE;



ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_ibfk_2 FOREIGN KEY (contributor_id) REFERENCES contributor(id) MATCH FULL;



ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_ibfk_3 FOREIGN KEY (publication_id) REFERENCES publication(id) MATCH FULL;



ALTER TABLE ONLY publication_file_map
    ADD CONSTRAINT publication_file_map_file_fkey FOREIGN KEY (file) REFERENCES file(identifier);



ALTER TABLE ONLY publication_file_map
    ADD CONSTRAINT publication_file_map_publication_fkey FOREIGN KEY (publication) REFERENCES publication(id);



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_ibfk_2 FOREIGN KEY (publication_type) REFERENCES publication_type(identifier) MATCH FULL;



ALTER TABLE ONLY publication_map
    ADD CONSTRAINT publication_map_child_fkey FOREIGN KEY (child) REFERENCES publication(id) ON DELETE CASCADE;



ALTER TABLE ONLY publication_map
    ADD CONSTRAINT publication_map_parent_fkey FOREIGN KEY (parent) REFERENCES publication(id) ON DELETE CASCADE;



ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_ibfk_1 FOREIGN KEY (type) REFERENCES ref_type(identifier) MATCH FULL;



ALTER TABLE ONLY report
    ADD CONSTRAINT report_organization_fkey FOREIGN KEY (organization) REFERENCES organization(identifier);



ALTER TABLE ONLY submitter
    ADD CONSTRAINT submitter_contributor_id_fkey FOREIGN KEY (contributor_id) REFERENCES contributor(id);



