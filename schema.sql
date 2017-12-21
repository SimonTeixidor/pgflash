CREATE EXTENSION pgcrypto;
-- CLEANUP
DROP SCHEMA IF EXISTS api CASCADE;
DROP TABLE IF EXISTS card CASCADE;
DROP TABLE IF EXISTS deck CASCADE;
DROP TABLE IF EXISTS flash_card_user CASCADE;
DROP ROLE IF EXISTS web_anon;
DROP FUNCTION public.create_db_role() CASCADE;
DROP FUNCTION public.encrypt_pass() CASCADE;

-- CREATE SCHEMAS
CREATE SCHEMA api;

-- TABLES
CREATE TABLE flash_card_user(
	name NAME PRIMARY KEY,
	pass TEXT
);
CREATE TABLE deck(
	owner NAME DEFAULT CURRENT_USER,
	name TEXT,
	public BOOLEAN DEFAULT FALSE,
	PRIMARY KEY (owner, name));
CREATE TABLE card(
       	front TEXT, 
	back TEXT,
	bucket INT,
	deck_user NAME,
	deck_name TEXT,
	FOREIGN KEY (deck_user, deck_name) REFERENCES deck(owner, name));

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
SELECT deck_user, deck_name, MAX(bucket) AS bucket FROM (
	SELECT deck_user, deck_name, bucket FROM card
	GROUP BY (deck_user, deck_name, bucket) HAVING COUNT(*) > POWER(bucket, 2)
) AS SUB GROUP BY (deck_user, deck_name);

CREATE VIEW next_card AS
-- The next card is either the first card in the overflowing
-- largest overflowing bucket, or a random card.
SELECT DISTINCT ON (c.deck_user,c.deck_name) c.* FROM (
	SELECT c.* FROM card c INNER JOIN next_bucket nb ON nb.deck_user = c.deck_user AND nb.deck_name = c.deck_name AND nb.bucket = c.bucket
	UNION ALL
	(SELECT * FROM card ORDER BY RANDOM())
) as c;
