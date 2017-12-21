DROP ROLE IF EXISTS web_anon;
DROP VIEW IF EXISTS next_bucket;
DROP VIEW IF EXISTS next_card;

-- The bucket from which the next card should be pulled is the first bucket
-- with more cards in it than the square of the bucket number. That is, we
-- pull a card from bucket 3 once it has more than 9 cards in it.
CREATE VIEW next_bucket AS
SELECT deck_owner, deck_name, MAX(bucket) AS bucket 
FROM bucket_count GROUP BY (deck_owner, deck_name);

-- The next card is either the first card in the overflowing
-- largest overflowing bucket, or a random card.
CREATE VIEW next_card AS
SELECT DISTINCT ON (c.deck_owner,c.deck_name) c.* FROM (
	SELECT c.* FROM card c INNER JOIN next_bucket nb ON nb.deck_owner = c.deck_owner AND nb.deck_name = c.deck_name AND nb.bucket = c.bucket
	UNION ALL
	(SELECT * FROM card ORDER BY RANDOM())
) as c;

-- Anon user can read all public decks.
CREATE ROLE web_anon NOLOGIN;
GRANT web_anon TO postgres;
GRANT SELECT ON deck TO web_anon;
