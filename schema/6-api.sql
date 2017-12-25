DROP VIEW IF EXISTS next_card;
DROP TYPE IF EXISTS answer_enum CASCADE;
CREATE EXTENSION IF NOT EXISTS pgjwt;
DROP ROLE IF EXISTS authenticator;
DROP ROLE IF EXISTS web_anon;

ALTER DATABASE simon SET "app.jwt_secret" TO 'reallyreallyreallyreallyverysafe';

CREATE VIEW pub.next_card AS
SELECT DISTINCT ON (c.deck_owner, c.deck_name) c.front,c.back,c.deck_owner,c.deck_name,c.bucket
FROM pub.card c 
INNER JOIN next_bucket nb 
ON nb.deck_owner = c.deck_owner AND nb.deck_name = c.deck_name AND nb.bucket = c.bucket
WHERE c.deck_owner = CURRENT_ROLE;

CREATE TYPE pub.answer_enum AS ENUM ('remembered', 'not_remembered');

CREATE FUNCTION pub.card_answer(f TEXT, b TEXT, dn TEXT, a pub.answer_enum) 
RETURNS void
LANGUAGE plpgsql
AS $$
  BEGIN
    UPDATE pub.card
    SET bucket = CASE WHEN a = 'remembered' THEN bucket + 1 ELSE 0 END
    WHERE front = f AND back = b AND deck_owner = CURRENT_ROLE AND deck_name = dn;
  END;
$$;

CREATE VIEW pub.public_deck AS SELECT * FROM pub.deck WHERE public;

-- Login function, from the postgrest docs.
CREATE FUNCTION pub.login(name TEXT, pass TEXT) RETURNS TEXT
  LANGUAGE PLPGSQL
  AS $$
DECLARE
  _role NAME;
  result TEXT;
BEGIN
  -- check name and password
  SELECT user_role(name, pass) INTO _role;
  IF _role IS NULL THEN
    RAISE invalid_password USING message = 'invalid user or password';
  END IF;

  SELECT sign(
      row_to_json(r), 'reallyreallyreallyreallyverysafe'
    ) AS token
    FROM (
      SELECT _role AS role, login.name AS name,
         extract(epoch from now())::integer + 60*60 AS exp
    ) r
    INTO result;
  RETURN result;
END;
$$;
    
-- Anon user can read all public decks.
CREATE ROLE web_anon NOLOGIN;
GRANT web_anon TO postgres;
GRANT USAGE ON SCHEMA pub TO web_anon;
GRANT SELECT ON pub.public_deck TO web_anon;
GRANT SELECT ON flash_card_user TO web_anon;
GRANT EXECUTE ON FUNCTION pub.login(TEXT, TEXT) TO web_anon;

-- Authenticator user is used to 
CREATE ROLE authenticator NOINHERIT;
GRANT web_anon TO authenticator;
