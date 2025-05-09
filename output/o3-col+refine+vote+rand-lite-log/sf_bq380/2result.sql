WITH received AS (
    SELECT
        "ToUserId"                          AS "UserId",
        COUNT(DISTINCT "Id")                AS "total_received_upvotes"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    GROUP BY "ToUserId"
),
given AS (
    SELECT
        "FromUserId"                        AS "UserId",
        COUNT(DISTINCT "Id")                AS "total_given_upvotes"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    GROUP BY "FromUserId"
)
SELECT
    u."UserName",
    r."total_received_upvotes",
    COALESCE(g."total_given_upvotes", 0)   AS "total_given_upvotes"
FROM received r
JOIN META_KAGGLE.META_KAGGLE."USERS" u
      ON u."Id" = r."UserId"
LEFT JOIN given g
      ON g."UserId" = r."UserId"
ORDER BY r."total_received_upvotes" DESC NULLS LAST
LIMIT 3;