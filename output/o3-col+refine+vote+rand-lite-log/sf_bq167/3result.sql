WITH pair_counts AS (   -- count distinct up-voted messages for every (giver → receiver) pair
    SELECT
        "FromUserId",
        "ToUserId",
        COUNT(DISTINCT "ForumMessageId") AS given_votes
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId","ToUserId"
),
reciprocal AS (         -- bring in the vote count in the opposite direction
    SELECT
        pc."FromUserId",
        pc."ToUserId",
        pc.given_votes,
        COALESCE(rpc.given_votes,0) AS returned_votes
    FROM pair_counts pc
    LEFT JOIN pair_counts rpc
           ON rpc."FromUserId" = pc."ToUserId"
          AND rpc."ToUserId"   = pc."FromUserId"
)
SELECT
    giver."UserName"    AS giver_username,
    receiver."UserName" AS receiver_username,
    rec.given_votes,
    rec.returned_votes
FROM reciprocal          rec
JOIN META_KAGGLE.META_KAGGLE.USERS giver
     ON giver."Id" = rec."FromUserId"
JOIN META_KAGGLE.META_KAGGLE.USERS receiver
     ON receiver."Id" = rec."ToUserId"
ORDER BY
    rec.given_votes   DESC NULLS LAST,   -- highest distinct up-votes received
    rec.returned_votes DESC NULLS LAST   -- break ties by reciprocity
LIMIT 1;