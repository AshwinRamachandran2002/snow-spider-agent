WITH received AS (
    SELECT 
        "ToUserId"  AS "UserId",
        COUNT(DISTINCT "Id") AS "ReceivedUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "ToUserId"
),
given AS (
    SELECT 
        "FromUserId" AS "UserId",
        COUNT(DISTINCT "Id") AS "GivenUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId"
)
SELECT 
    u."UserName",
    r."ReceivedUpvotes",
    COALESCE(g."GivenUpvotes", 0) AS "GivenUpvotes"
FROM received r
JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = r."UserId"
LEFT JOIN given g
      ON g."UserId" = r."UserId"
ORDER BY r."ReceivedUpvotes" DESC NULLS LAST
FETCH 3 ROWS ONLY;