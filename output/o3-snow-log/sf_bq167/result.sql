/* Find the user–pair with the highest one-way up-vote count
   and show the reciprocal count in the opposite direction        */

WITH pair_counts AS (               -- 1) # of votes each giver → receiver
    SELECT
        "FromUserId" ,
        "ToUserId"   ,
        COUNT(*)      AS "votes_from_to"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId", "ToUserId"
),

pairs_with_return AS (              -- 2) attach reverse-direction counts
    SELECT
        pc."FromUserId" ,
        pc."ToUserId"   ,
        pc."votes_from_to",
        COALESCE(rc."votes_from_to", 0) AS "votes_to_from"
    FROM pair_counts pc
    LEFT JOIN pair_counts rc
           ON rc."FromUserId" = pc."ToUserId"
          AND rc."ToUserId"   = pc."FromUserId"
)

SELECT
    fu."UserName" AS "giver_username",      -- the one who cast the most votes
    tu."UserName" AS "receiver_username",   -- the recipient of those votes
    pw."votes_from_to"  AS "upvotes_given", -- distinct up-votes giver → receiver
    pw."votes_to_from"  AS "upvotes_returned" -- votes the receiver gave back
FROM pairs_with_return pw
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS fu ON fu."Id" = pw."FromUserId"
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS tu ON tu."Id" = pw."ToUserId"
ORDER BY
    pw."votes_from_to" DESC NULLS LAST,     -- highest one-way total first
    pw."votes_to_from" DESC NULLS LAST      -- tie-break by reciprocal count
LIMIT 1;