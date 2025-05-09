WITH received AS (
    SELECT
        "ToUserId"                            AS "UserId",
        COUNT(DISTINCT "FromUserId")          AS "distinct_upvotes_received"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    GROUP BY "ToUserId"
),
given AS (
    SELECT
        "FromUserId"                          AS "UserId",
        COUNT(DISTINCT "ForumMessageId")      AS "distinct_upvotes_given"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    GROUP BY "FromUserId"
)
SELECT
    u."UserName",
    r."distinct_upvotes_received",
    COALESCE(g."distinct_upvotes_given", 0)  AS "distinct_upvotes_given"
FROM received r
JOIN META_KAGGLE.META_KAGGLE."USERS" u
          ON u."Id" = r."UserId"
LEFT JOIN given g
          ON g."UserId" = r."UserId"
ORDER BY r."distinct_upvotes_received" DESC NULLS LAST
LIMIT 3;