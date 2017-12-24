DROP VIEW IF EXISTS next_bucket;
DROP VIEW IF EXISTS full_bucket;
DROP VIEW IF EXISTS smallest_bucket_with_no_full;

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
