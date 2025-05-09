WITH received AS (
    SELECT 
        "ToUserId"  AS "UserId",
        COUNT(DISTINCT "Id") AS "Distinct_Upvotes_Received"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "ToUserId"
),
given AS (
    SELECT 
        "FromUserId" AS "UserId",
        COUNT(DISTINCT "Id") AS "Distinct_Upvotes_Given"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId"
)
SELECT 
    u."UserName",
    r."Distinct_Upvotes_Received",
    COALESCE(g."Distinct_Upvotes_Given", 0) AS "Distinct_Upvotes_Given"
FROM received r
LEFT JOIN given g
       ON r."UserId" = g."UserId"
JOIN META_KAGGLE.META_KAGGLE.USERS u
     ON u."Id" = r."UserId"
ORDER BY r."Distinct_Upvotes_Received" DESC NULLS LAST
LIMIT 3;