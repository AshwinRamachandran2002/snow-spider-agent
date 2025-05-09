WITH received AS (
    SELECT
        "ToUserId"                                  AS "UserId",
        COUNT(DISTINCT "FromUserId")                AS "total_distinct_upvotes_received"
    FROM   "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    WHERE  "ToUserId" IS NOT NULL
    GROUP  BY "ToUserId"
),
given AS (
    SELECT
        "FromUserId"                                AS "UserId",
        COUNT(DISTINCT "ToUserId")                  AS "total_distinct_upvotes_given"
    FROM   "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    WHERE  "FromUserId" IS NOT NULL
    GROUP  BY "FromUserId"
)
SELECT
    u."UserName",
    r."total_distinct_upvotes_received",
    COALESCE(g."total_distinct_upvotes_given", 0)  AS "total_distinct_upvotes_given"
FROM    received r
LEFT JOIN given g ON r."UserId" = g."UserId"
JOIN    "META_KAGGLE"."META_KAGGLE"."USERS" u
        ON u."Id" = r."UserId"
ORDER BY r."total_distinct_upvotes_received" DESC NULLS LAST
LIMIT 3;