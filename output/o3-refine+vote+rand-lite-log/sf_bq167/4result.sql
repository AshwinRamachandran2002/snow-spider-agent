WITH "PAIR_COUNTS" AS (          -- how many times one user up‑voted another
    SELECT
        "ToUserId"   AS "RECIPIENT_ID",
        "FromUserId" AS "GIVER_ID",
        COUNT(DISTINCT "ForumMessageId") AS "VOTES"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
      AND "FromUserId" IS NOT NULL
    GROUP BY "RECIPIENT_ID", "GIVER_ID"
),

"COMBINED" AS (                  -- add the count going in the reverse direction
    SELECT
        pc."RECIPIENT_ID"                   AS "USER_A_ID",   -- gets the votes
        pc."GIVER_ID"                       AS "USER_B_ID",   -- gives the votes
        pc."VOTES"                          AS "VOTES_B_TO_A",
        COALESCE(pc2."VOTES", 0)            AS "VOTES_A_TO_B"
    FROM "PAIR_COUNTS" pc
    LEFT JOIN "PAIR_COUNTS" pc2
           ON pc2."RECIPIENT_ID" = pc."GIVER_ID"
          AND pc2."GIVER_ID"     = pc."RECIPIENT_ID"
)

SELECT
    ua."UserName" AS "RECIPIENT_USERNAME",
    ub."UserName" AS "GIVER_USERNAME",
    c."VOTES_B_TO_A" AS "UPVOTES_RECEIVED",
    c."VOTES_A_TO_B" AS "UPVOTES_RETURNED"
FROM "COMBINED" c
JOIN META_KAGGLE.META_KAGGLE.USERS ua   ON ua."Id" = c."USER_A_ID"
JOIN META_KAGGLE.META_KAGGLE.USERS ub   ON ub."Id" = c."USER_B_ID"
ORDER BY
    c."VOTES_B_TO_A" DESC NULLS LAST,   -- most received
    c."VOTES_A_TO_B" DESC NULLS LAST    -- then most returned
LIMIT 1;