create trigger updatepub before update on platform for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();
create trigger updatepub before update on instrument for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();
create trigger delpub before delete on platform for each row execute procedure delete_publication();
create trigger delpub before delete on instrument for each row execute procedure delete_publication();

