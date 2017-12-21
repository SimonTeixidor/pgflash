CREATE EXTENSION pgcrypto;
-- CLEANUP
DROP SCHEMA IF EXISTS api CASCADE;
DROP TABLE IF EXISTS card CASCADE;
DROP TABLE IF EXISTS deck CASCADE;
DROP TABLE IF EXISTS flash_card_user CASCADE;
DROP TABLE IF EXISTS bucket_count CASCADE;
DROP ROLE IF EXISTS web_anon;
DROP FUNCTION create_db_role() CASCADE;
DROP FUNCTION encrypt_pass() CASCADE;
DROP FUNCTION increment_bucket_count();
DROP FUNCTION decrement_bucket_count();

-- CREATE SCHEMAS
CREATE SCHEMA api;

-- TABLES
CREATE TABLE flash_card_user(
	name NAME PRIMARY KEY NOT NULL,
	pass TEXT NOT NULL
);
CREATE TABLE deck(
	owner NAME NOT NULL DEFAULT CURRENT_USER references flash_card_user(name),
	name TEXT NOT NULL,
	public BOOLEAN DEFAULT FALSE NOT NULL,
	PRIMARY KEY (owner, name));
CREATE TABLE bucket_count(
	deck_owner NAME NOT NULL,
	deck_name TEXT NOT NULL,
	bucket INT NOT NULL,
	count INT NOT NULL,
	PRIMARY KEY (deck_owner, deck_name, bucket));
CREATE TABLE card(
       	front TEXT NOT NULL, 
	back TEXT NOT NULL,
	bucket INT NOT NULL,
	deck_owner NAME NOT NULL,
	deck_name TEXT NOT NULL,
	PRIMARY KEY (front, back, deck_owner, deck_name),
	FOREIGN KEY (deck_owner, deck_name) REFERENCES deck(owner, name));

-- AUTH
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
    RETURN new;
  END
$$;

CREATE TRIGGER create_db_role_on_insert
BEFORE INSERT on flash_card_user
FOR EACH ROW
EXECUTE PROCEDURE create_db_role();

CREATE POLICY deck_policy ON deck
USING (owner = current_user OR EXISTS (SELECT 1 FROM deck WHERE public))
WITH CHECK (owner = current_user);

-- PUBLIC ROLE
CREATE ROLE web_anon NOLOGIN;
GRANT web_anon TO postgres;

GRANT USAGE ON SCHEMA api TO web_anon;
GRANT SELECT ON deck TO web_anon;

-- CORE LOGIC

-- The bucket from which the next card should be pulled is the first bucket
-- with more cards in it than the square of the bucket number. That is, we
-- pull a card from bucket 3 once it has more than 9 cards in it.
CREATE VIEW next_bucket AS
SELECT deck_owner, deck_name, MAX(bucket) AS bucket FROM (
	SELECT deck_owner, deck_name, bucket FROM card
	GROUP BY (deck_owner, deck_name, bucket) HAVING COUNT(*) > POWER(bucket, 2)
) AS SUB GROUP BY (deck_owner, deck_name);

CREATE VIEW next_card AS
-- The next card is either the first card in the overflowing
-- largest overflowing bucket, or a random card.
SELECT DISTINCT ON (c.deck_owner,c.deck_name) c.* FROM (
	SELECT c.* FROM card c INNER JOIN next_bucket nb ON nb.deck_owner = c.deck_owner AND nb.deck_name = c.deck_name AND nb.bucket = c.bucket
	UNION ALL
	(SELECT * FROM card ORDER BY RANDOM())
) as c;

CREATE FUNCTION increment_bucket_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    -- Increment the count if the bucket already exists
    UPDATE bucket_count SET count = count + 1 
    WHERE bucket = new.bucket and deck_owner = new.deck_owner and deck_name = new.deck_name;

    -- Otherwise create a new entry
    INSERT INTO bucket_count (bucket, deck_owner, deck_name, count) 
    (
      SELECT new.bucket,new.deck_owner,new.deck_name,1
      WHERE NOT EXISTS(
        SELECT 1 FROM bucket_count bc 
        WHERE bc.bucket=new.bucket AND bc.deck_owner=new.deck_owner AND bc.deck_name=new.deck_name
      )
    );
    RETURN NEW;
  END;
$$;

CREATE FUNCTION decrement_bucket_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    UPDATE bucket_count SET count = count - 1
    WHERE bucket = old.bucket and deck_owner = old.deck_owner and deck_name = old.deck_name;
    DELETE FROM bucket_count WHERE count = 0;
    RETURN NEW;
  END;
$$;

CREATE TRIGGER bucket_count_update_new
BEFORE INSERT OR UPDATE on card
FOR EACH ROW
EXECUTE PROCEDURE increment_bucket_count();

CREATE TRIGGER bucket_count_update_old
BEFORE UPDATE on card
FOR EACH ROW
EXECUTE PROCEDURE decrement_bucket_count();
