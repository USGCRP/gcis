create trigger update_exterms before update on organization for each row when (NEW.identifier != OLD.identifier) execute procedure update_exterms('/organization/');

