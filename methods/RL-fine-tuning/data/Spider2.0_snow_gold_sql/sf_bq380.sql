WITH
Received AS (
    SELECT "ToUserId", COUNT(DISTINCT "FromUserId") AS "Total_upvotes_received"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    GROUP BY "ToUserId"
),
Given AS (
    SELECT "FromUserId", COUNT(DISTINCT "ToUserId") AS "Total_upvotes_given"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    GROUP BY "FromUserId"
)
SELECT U."UserName",
       R."Total_upvotes_received",
       COALESCE(G."Total_upvotes_given", 0) AS "Total_upvotes_given"
FROM Received R
JOIN META_KAGGLE.META_KAGGLE."USERS" U ON R."ToUserId" = U."Id"
LEFT JOIN Given G ON U."Id" = G."FromUserId"
ORDER BY R."Total_upvotes_received" DESC NULLS LAST
LIMIT 3;