--For making toolkits and case studies look like a full-fledged resource
CREATE OR REPLACE VIEW toolkit as select t.lexicon_identifier, t.context_identifier, t.term, m.* from term t, term_map m where t.identifier=m.term_identifier and m.relationship_identifier = 'hasAnalysisTool';
CREATE OR REPLACE VIEW case_study as select t.lexicon_identifier, t.context_identifier, t.term, m.* from term t, term_map m where t.identifier=m.term_identifier and m.relationship_identifier = 'hasCaseStudy';

--Quick fix for specifying featured reports
ALTER TABLE report ADD COLUMN _featured_priority integer;
UPDATE REPORT SET _featured_priority=1 WHERE identifier = 'usgcrp-climate-human-health-assessment-2016';
UPDATE REPORT SET _featured_priority=2 WHERE identifier = 'nca3';
