CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TABLE IF EXISTS flash_card_user CASCADE;
DROP FUNCTION IF EXISTS create_db_role() CASCADE;
DROP FUNCTION IF EXISTS encrypt_pass() CASCADE;

CREATE TABLE flash_card_user(
	name NAME PRIMARY KEY NOT NULL,
	pass TEXT NOT NULL
);

CREATE FUNCTION encrypt_pass()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    new.pass = crypt(new.pass, gen_salt('bf'));
    RETURN new;
  END;
$$;

CREATE TRIGGER encrypt_pass_on_insert
BEFORE INSERT on flash_card_user
FOR EACH ROW
EXECUTE PROCEDURE encrypt_pass();

CREATE FUNCTION create_db_role()
RETURNS TRIGGER
LANGUAGE plpgsql
as $$
  BEGIN
    EXECUTE 'CREATE ROLE ' || quote_ident(new.name);
    EXECUTE 'GRANT SELECT ON deck TO ' || quote_ident(new.name);
    EXECUTE 'GRANT SELECT ON next_card TO ' || quote_ident(new.name);
    EXECUTE 'GRANT EXECUTE ON FUNCTION card_answer(TEXT, TEXT, TEXT, answer_enum) TO ' 
      || quote_ident(new.name);
    EXECUTE 'GRANT ALL ON card TO ' || quote_ident(new.name);
    EXECUTE 'GRANT ALL ON bucket_count TO ' || quote_ident(new.name);
    RETURN new;
  END
$$;

CREATE TRIGGER create_db_role_on_insert
BEFORE INSERT on flash_card_user
FOR EACH ROW
EXECUTE PROCEDURE create_db_role();
