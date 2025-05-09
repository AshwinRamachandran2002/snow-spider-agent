WITH received AS (
    SELECT 
        "ToUserId"      AS "UserId",
        COUNT(DISTINCT "Id") AS "ReceivedUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
), 
given AS (
    SELECT 
        "FromUserId"    AS "UserId",
        COUNT(DISTINCT "Id") AS "GivenUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
), 
combined AS (
    SELECT 
        r."UserId",
        r."ReceivedUpvotes",
        COALESCE(g."GivenUpvotes", 0) AS "GivenUpvotes"
    FROM received r
    LEFT JOIN given g
        ON r."UserId" = g."UserId"
)
SELECT 
    u."UserName",
    c."ReceivedUpvotes",
    c."GivenUpvotes"
FROM combined c
JOIN META_KAGGLE.META_KAGGLE.USERS u
    ON c."UserId" = u."Id"
ORDER BY 
    c."ReceivedUpvotes" DESC NULLS LAST
LIMIT 3;