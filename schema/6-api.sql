DROP ROLE IF EXISTS web_anon;
DROP VIEW IF EXISTS next_card;
DROP TYPE IF EXISTS answer_enum CASCADE;

CREATE VIEW next_card AS
SELECT DISTINCT ON (c.deck_owner, c.deck_name) c.front,c.back,c.deck_owner,c.deck_name,c.bucket
FROM card c 
INNER JOIN next_bucket nb 
ON nb.deck_owner = c.deck_owner AND nb.deck_name = c.deck_name AND nb.bucket = c.bucket
WHERE c.deck_owner = CURRENT_ROLE;

CREATE TYPE answer_enum AS ENUM ('remembered', 'not_remembered');

CREATE FUNCTION card_answer(f TEXT, b TEXT, dn TEXT, a answer_enum) 
RETURNS void
LANGUAGE plpgsql
AS $$
  BEGIN
    UPDATE card
    SET bucket = CASE WHEN a = 'remembered' THEN bucket + 1 ELSE 0 END
    WHERE front = f AND back = b AND deck_owner = CURRENT_ROLE AND deck_name = dn;
  END;
$$;
    
-- Anon user can read all public decks.
CREATE ROLE web_anon NOLOGIN;
GRANT web_anon TO postgres;
GRANT SELECT ON deck TO web_anon;
