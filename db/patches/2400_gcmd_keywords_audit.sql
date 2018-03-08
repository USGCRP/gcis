CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON gcmd_keyword FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');
CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON gcmd_keyword FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');
