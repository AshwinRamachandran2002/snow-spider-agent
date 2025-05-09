WITH distinct_received AS (
    SELECT 
        "ToUserId"              AS "UserId",
        COUNT(DISTINCT "FromUserId") AS "distinct_votes_received"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "ToUserId"
),
distinct_given AS (
    SELECT 
        "FromUserId"            AS "UserId",
        COUNT(DISTINCT "ToUserId")   AS "distinct_votes_given"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId"
),
top3 AS (
    SELECT 
        "UserId",
        "distinct_votes_received"
    FROM distinct_received
    ORDER BY "distinct_votes_received" DESC
    LIMIT 3
)
SELECT
    u."UserName",
    t."distinct_votes_received",
    COALESCE(g."distinct_votes_given", 0) AS "distinct_votes_given"
FROM top3 t
LEFT JOIN distinct_given g
       ON t."UserId" = g."UserId"
JOIN META_KAGGLE.META_KAGGLE.USERS u
       ON u."Id" = t."UserId"
ORDER BY t."distinct_votes_received" DESC;