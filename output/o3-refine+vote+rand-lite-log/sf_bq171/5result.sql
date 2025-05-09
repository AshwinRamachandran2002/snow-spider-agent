WITH "user_votes" AS (
    SELECT 
        "ToUserId"               AS "user_id",
        COUNT(*)                 AS "upvotes_2019"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    WHERE "VoteDate" >= '2019-01-01' 
      AND "VoteDate" <  '2020-01-01'
    GROUP BY "ToUserId"
),
"votes_with_avg" AS (
    SELECT 
        "user_id",
        "upvotes_2019",
        AVG("upvotes_2019") OVER ()        AS "avg_upvotes",
        ABS("upvotes_2019" - AVG("upvotes_2019") OVER ()) AS "diff"
    FROM "user_votes"
),
"min_diff" AS (
    SELECT MIN("diff") AS "min_diff_val" 
    FROM "votes_with_avg"
)
SELECT 
    u."UserName"
FROM "votes_with_avg" v
JOIN "min_diff" m                ON v."diff" = m."min_diff_val"
JOIN META_KAGGLE.META_KAGGLE."USERS" u 
     ON u."Id" = v."user_id"
ORDER BY u."UserName" ASC
LIMIT 1;