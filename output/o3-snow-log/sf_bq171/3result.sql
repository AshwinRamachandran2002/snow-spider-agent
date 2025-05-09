WITH per_user AS (      -- upvotes each user received in 2019
    SELECT 
        "ToUserId"                AS "UserId",
        COUNT(*)                  AS "Upvotes2019"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE EXTRACT(year FROM "VoteDate") = 2019
    GROUP BY "ToUserId"
),
avg_val AS (            -- average upvotes across users
    SELECT AVG("Upvotes2019") AS "AvgVotes"
    FROM per_user
),
diffs AS (              -- distance of each user’s total from the average
    SELECT 
        u."UserName",
        p."Upvotes2019",
        ABS(p."Upvotes2019" - a."AvgVotes") AS "Diff"
    FROM per_user p
    CROSS JOIN avg_val a
    JOIN META_KAGGLE.META_KAGGLE.USERS u
          ON u."Id" = p."UserId"
)
SELECT "UserName"
FROM diffs
ORDER BY "Diff" ASC, "UserName" ASC      -- closest to average, tiebreak by name
LIMIT 1;