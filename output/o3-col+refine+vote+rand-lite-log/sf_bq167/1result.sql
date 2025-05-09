/* top giver → receiver pair by distinct up-votes (and the return flow) */
WITH vote_counts AS (      -- distinct up-votes in each direction
    SELECT 
        "FromUserId"  AS giver_id,
        "ToUserId"    AS receiver_id,
        COUNT(DISTINCT "ForumMessageId") AS votes_forward
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" > 0                -- keep only real Kaggle users
      AND "ToUserId"   > 0
    GROUP BY giver_id, receiver_id
), paired AS (            -- attach the reciprocal count
    SELECT
        v.giver_id,
        v.receiver_id,
        v.votes_forward,
        COALESCE(r.votes_forward, 0) AS votes_back
    FROM vote_counts v
    LEFT JOIN vote_counts r
           ON r.giver_id   = v.receiver_id
          AND r.receiver_id = v.giver_id
)
SELECT
    gu."UserName" AS giver_username,
    ru."UserName" AS receiver_username,
    p.votes_forward  AS distinct_upvotes_given,
    p.votes_back     AS distinct_upvotes_returned
FROM paired p
JOIN META_KAGGLE.META_KAGGLE.USERS gu ON gu."Id" = p.giver_id
JOIN META_KAGGLE.META_KAGGLE.USERS ru ON ru."Id" = p.receiver_id
ORDER BY p.votes_forward DESC NULLS LAST,
         p.votes_back    DESC NULLS LAST
LIMIT 1;