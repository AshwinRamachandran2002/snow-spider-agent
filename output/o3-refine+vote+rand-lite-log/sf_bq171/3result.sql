WITH per_user AS (   -- upvotes each user received in 2019
    SELECT 
        "ToUserId" AS "UserId",
        COUNT(*)   AS "Upvotes"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    WHERE "VoteDate" >= '2019-01-01'
      AND "VoteDate" <  '2020-01-01'
    GROUP BY "ToUserId"
), avg_stats AS (     -- add overall average
    SELECT 
        "UserId",
        "Upvotes",
        AVG("Upvotes") OVER () AS "AvgUpvotes"
    FROM per_user
), distances AS (     -- distance from the average
    SELECT 
        "UserId",
        ABS("Upvotes" - "AvgUpvotes") AS "DiffFromAvg"
    FROM avg_stats
)
SELECT  u."UserName"
FROM    distances d
JOIN    META_KAGGLE.META_KAGGLE."USERS" u
       ON u."Id" = d."UserId"
ORDER BY d."DiffFromAvg" ASC,         -- closest to the average
         u."UserName"  ASC            -- alphabetical tie‑breaker
LIMIT 1;