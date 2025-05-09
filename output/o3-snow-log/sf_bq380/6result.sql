WITH received AS (
    SELECT 
        "ToUserId"                                AS "UserId",
        COUNT(DISTINCT "Id")                      AS "UpvotesReceived"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
given AS (
    SELECT 
        "FromUserId"                              AS "UserId",
        COUNT(DISTINCT "Id")                      AS "UpvotesGiven"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
)
SELECT
    u."UserName",
    r."UpvotesReceived",
    COALESCE(g."UpvotesGiven", 0)                AS "UpvotesGiven"
FROM received r
LEFT JOIN given g
       ON r."UserId" = g."UserId"
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u
       ON r."UserId" = u."Id"
ORDER BY r."UpvotesReceived" DESC NULLS LAST
LIMIT 3;