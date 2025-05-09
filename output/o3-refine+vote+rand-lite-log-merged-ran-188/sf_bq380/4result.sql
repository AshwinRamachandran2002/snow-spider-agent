WITH received AS (
    SELECT
        "ToUserId"                          AS "UserId",
        COUNT(DISTINCT "Id")                AS "Upvotes_Received"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
given AS (
    SELECT
        "FromUserId"                        AS "UserId",
        COUNT(DISTINCT "Id")                AS "Upvotes_Given"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
),
combined AS (
    SELECT
        u."UserName",
        COALESCE(r."Upvotes_Received", 0)   AS "Upvotes_Received",
        COALESCE(g."Upvotes_Given", 0)      AS "Upvotes_Given"
    FROM META_KAGGLE.META_KAGGLE.USERS u
    JOIN received r ON u."Id" = r."UserId"
    LEFT JOIN given  g ON u."Id" = g."UserId"
)
SELECT
    "UserName",
    "Upvotes_Received",
    "Upvotes_Given"
FROM combined
ORDER BY "Upvotes_Received" DESC NULLS LAST, "UserName"
LIMIT 3;