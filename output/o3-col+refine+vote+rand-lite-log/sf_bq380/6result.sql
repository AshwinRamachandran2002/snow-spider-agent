WITH received AS (
    SELECT 
        "ToUserId"          AS "UserId",
        COUNT(DISTINCT "Id") AS "received_cnt"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "ToUserId"
), 
given AS (
    SELECT 
        "FromUserId"        AS "UserId",
        COUNT(DISTINCT "Id") AS "given_cnt"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId"
), 
top3 AS (
    SELECT *
    FROM received
    ORDER BY "received_cnt" DESC NULLS LAST
    LIMIT 3
)
SELECT 
    u."UserName",
    t."received_cnt",
    COALESCE(g."given_cnt", 0) AS "given_cnt"
FROM top3 t
JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = t."UserId"
LEFT JOIN given g
      ON g."UserId" = t."UserId"
ORDER BY t."received_cnt" DESC NULLS LAST;