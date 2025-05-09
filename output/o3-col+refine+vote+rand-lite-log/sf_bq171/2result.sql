WITH user_votes AS (
    SELECT 
        "ToUserId",
        COUNT(*) AS "votes_2019"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY "ToUserId"
),
avg_votes AS (
    SELECT AVG("votes_2019") AS "avg_votes_2019"
    FROM user_votes
),
distances AS (
    SELECT
        u."UserName",
        v."votes_2019",
        ABS(v."votes_2019" - a."avg_votes_2019") AS "distance_from_avg"
    FROM user_votes v
    CROSS JOIN avg_votes a
    JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = v."ToUserId"
)
SELECT 
    "UserName"        AS "closest_user",
    "votes_2019"      AS "user_votes_2019",
    "distance_from_avg"
FROM distances
WHERE "UserName" IS NOT NULL
ORDER BY 
    "distance_from_avg" ASC,
    "UserName"         ASC
LIMIT 1;