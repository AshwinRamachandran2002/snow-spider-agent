WITH received AS (
    SELECT 
        "ToUserId"   AS "UserId",
        COUNT(DISTINCT "Id") AS "received_upvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
), 
given AS (
    SELECT
        "FromUserId" AS "UserId",
        COUNT(DISTINCT "Id") AS "given_upvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
)
SELECT
    u."UserName",
    r."received_upvotes",
    COALESCE(g."given_upvotes", 0) AS "given_upvotes"
FROM received r
JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = r."UserId"
LEFT JOIN given g
      ON g."UserId" = r."UserId"
ORDER BY r."received_upvotes" DESC NULLS LAST, u."UserName"
LIMIT 3;