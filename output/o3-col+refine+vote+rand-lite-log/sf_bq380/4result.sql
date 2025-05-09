WITH received AS (
    SELECT 
        "ToUserId" AS "UserId",
        COUNT(DISTINCT "Id") AS "upvotes_received"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "ToUserId"
),
given AS (
    SELECT 
        "FromUserId" AS "UserId",
        COUNT(DISTINCT "Id") AS "upvotes_given"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId"
)
SELECT 
    u."UserName",
    r."upvotes_received",
    COALESCE(g."upvotes_given", 0) AS "upvotes_given"
FROM received r
LEFT JOIN given g
       ON r."UserId" = g."UserId"
JOIN META_KAGGLE.META_KAGGLE.USERS u
     ON u."Id" = r."UserId"
ORDER BY r."upvotes_received" DESC NULLS LAST
LIMIT 3;