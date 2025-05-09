WITH received AS (
    SELECT 
        "ToUserId" AS "UserId",
        COUNT(DISTINCT "Id") AS "upvotes_received"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
given AS (
    SELECT 
        "FromUserId" AS "UserId",
        COUNT(DISTINCT "Id") AS "upvotes_given"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
)
SELECT
    u."UserName"                       AS "username",
    r."upvotes_received",
    COALESCE(g."upvotes_given", 0)     AS "upvotes_given"
FROM received r
JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = r."UserId"
LEFT JOIN given g
       ON g."UserId" = r."UserId"
ORDER BY r."upvotes_received" DESC NULLS LAST,
         u."UserName"
LIMIT 3;