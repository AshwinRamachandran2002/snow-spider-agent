WITH pair_votes AS (            -- 1. distinct up-votes each user gave another
    SELECT
        "FromUserId",
        "ToUserId",
        COUNT(DISTINCT "ForumMessageId") AS "distinct_votes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" > 0          -- skip anonymous / deleted users
      AND "ToUserId"   > 0
    GROUP BY "FromUserId", "ToUserId"
),
paired AS (                       -- 2. attach the reply-flow in the other direction
    SELECT
        p1."FromUserId"                  AS "giver_id",
        p1."ToUserId"                    AS "receiver_id",
        p1."distinct_votes"              AS "votes_received",
        COALESCE(p2."distinct_votes",0)  AS "votes_returned"
    FROM pair_votes p1
    LEFT JOIN pair_votes p2
           ON p2."FromUserId" = p1."ToUserId"
          AND p2."ToUserId"   = p1."FromUserId"
),
ranked AS (                      -- 3. rank by most received, then most returned
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY "votes_received" DESC,
                                     "votes_returned" DESC) AS "rn"
    FROM paired
)
-- 4. pick the single best pair and show usernames + counts
SELECT
    giver."UserName"    AS "giver_username",
    receiver."UserName" AS "receiver_username",
    ranked."votes_received",
    ranked."votes_returned"
FROM ranked
JOIN META_KAGGLE.META_KAGGLE.USERS giver
     ON giver."Id" = ranked."giver_id"
JOIN META_KAGGLE.META_KAGGLE.USERS receiver
     ON receiver."Id" = ranked."receiver_id"
WHERE ranked."rn" = 1;