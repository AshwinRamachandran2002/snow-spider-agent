WITH recv AS (   -- distinct votes each user received
    SELECT
        "ToUserId"                       AS "UserId",
        COUNT(DISTINCT "Id")             AS "upvotes_received"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
sent AS (   -- distinct votes each user gave
    SELECT
        "FromUserId"                     AS "UserId",
        COUNT(DISTINCT "Id")             AS "upvotes_given"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
),
combined AS (
    SELECT
        r."UserId",
        r."upvotes_received",
        COALESCE(s."upvotes_given", 0)   AS "upvotes_given"
    FROM recv r
    LEFT JOIN sent s
           ON r."UserId" = s."UserId"
)
SELECT
    u."UserName"        AS username,
    c."upvotes_received",
    c."upvotes_given"
FROM combined c
JOIN META_KAGGLE.META_KAGGLE.USERS u
  ON u."Id" = c."UserId"
ORDER BY c."upvotes_received" DESC NULLS LAST,
         username
LIMIT 3;