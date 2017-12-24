DROP ROLE IF EXISTS web_anon;
DROP VIEW IF EXISTS next_bucket;
DROP VIEW IF EXISTS next_card;

-- If there are many full buckets, we start from the largest bucket.
CREATE VIEW full_bucket AS
SELECT bc.deck_owner, bc.deck_name, MAX(bc.bucket) AS bucket
FROM bucket_count bc
WHERE POWER(bc.bucket,2)<bc.count
GROUP BY(bc.deck_owner, bc.deck_name);

-- If there is no full bucket, we start from the smallest bucket.
CREATE VIEW smallest_bucket_with_no_full AS
SELECT bc.deck_owner, bc.deck_name, MIN(bc.bucket) AS bucket
FROM bucket_count bc
LEFT JOIN full_bucket fbc ON fbc.deck_owner=bc.deck_owner AND fbc.deck_name=bc.deck_name
WHERE fbc.deck_owner IS NULL
GROUP BY(bc.deck_owner, bc.deck_name);

CREATE VIEW next_bucket AS
SELECT * FROM full_bucket 
UNION ALL 
SELECT * FROM smallest_bucket_with_no_full;
		
-- The next card is either the first card in the overflowing
-- largest overflowing bucket, or a random card.
CREATE VIEW next_card AS
SELECT DISTINCT ON (c.deck_owner,c.deck_name) c.front,c.back,c.deck_owner,c.deck_name,c.bucket FROM (
  (
    (SELECT 1 AS sort_nr, c.* FROM card c INNER JOIN next_bucket nb ON nb.deck_owner = c.deck_owner AND nb.deck_name = c.deck_name AND nb.bucket = c.bucket order by c.front)
    UNION ALL
    (SELECT 2 AS sort_nr, c.* FROM card c ORDER BY (c.bucket,c.front))
  ) ORDER BY sort_nr
) as c where c.deck_owner = CURRENT_ROLE;

-- Anon user can read all public decks.
CREATE ROLE web_anon NOLOGIN;
GRANT web_anon TO postgres;
GRANT SELECT ON deck TO web_anon;
