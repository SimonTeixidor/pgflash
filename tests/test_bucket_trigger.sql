BEGIN;
-- Verify bucket count table matches a group and count.
SELECT '[ERROR] bucket_count columns does not match group and count:', *
FROM bucket_count bc
INNER JOIN (
  SELECT deck_owner,deck_name,bucket,count(*) as count FROM card c
  GROUP BY (deck_owner, deck_name, bucket)
) sub ON sub.deck_owner = bc.deck_owner AND sub.deck_name = bc.deck_name
         AND sub.bucket = bc.bucket
WHERE sub.count != bc.count;
ROLLBACK;
