WITH "USER_VOTES" AS (          -- up-votes per user during 2019
    SELECT  "ToUserId",
            COUNT(*) AS "Upvotes2019"
    FROM    META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    WHERE   "VoteDate" BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY "ToUserId"
),
"AVG_VAL" AS (                  -- overall average
    SELECT AVG("Upvotes2019") AS "AvgUpvotes2019"
    FROM   "USER_VOTES"
),
"DIFFS" AS (                    -- distance of each user from the average
    SELECT  u."UserName",
            v."Upvotes2019",
            ABS(v."Upvotes2019" - a."AvgUpvotes2019") AS "DiffFromAvg"
    FROM    "USER_VOTES" v
    JOIN    META_KAGGLE.META_KAGGLE."USERS" u
            ON u."Id" = v."ToUserId"
    CROSS JOIN "AVG_VAL" a
)
SELECT  "UserName",
        "Upvotes2019",
        "DiffFromAvg"
FROM    "DIFFS"
ORDER BY "DiffFromAvg" ASC,
         "UserName"   ASC        -- tie-break alphabetically
LIMIT   1;