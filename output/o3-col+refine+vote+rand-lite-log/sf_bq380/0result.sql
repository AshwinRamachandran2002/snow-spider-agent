WITH received AS (
    SELECT
        "ToUserId"                               AS "UserId",
        COUNT(DISTINCT "Id")                     AS "distinct_upvotes_received"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "ToUserId"
),
given AS (
    SELECT
        "FromUserId"                             AS "UserId",
        COUNT(DISTINCT "Id")                     AS "distinct_upvotes_given"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId"
),
combined AS (
    SELECT
        r."UserId",
        r."distinct_upvotes_received",
        COALESCE(g."distinct_upvotes_given", 0) AS "distinct_upvotes_given"
    FROM received r
    LEFT JOIN given g
           ON r."UserId" = g."UserId"
)
SELECT
    u."UserName",
    c."distinct_upvotes_received",
    c."distinct_upvotes_given"
FROM combined c
JOIN META_KAGGLE.META_KAGGLE.USERS u
     ON u."Id" = c."UserId"
ORDER BY c."distinct_upvotes_received" DESC NULLS LAST
LIMIT 3;