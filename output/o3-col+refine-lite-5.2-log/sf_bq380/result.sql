SELECT
    u."UserName",
    r."Distinct_Upvotes_Received",
    COALESCE(g."Distinct_Upvotes_Given", 0) AS "Distinct_Upvotes_Given"
FROM (
    /* Up‑votes received per user */
    SELECT
        "ToUserId"                        AS "UserId",
        COUNT(DISTINCT "Id")              AS "Distinct_Upvotes_Received"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
) r
LEFT JOIN (
    /* Up‑votes given per user */
    SELECT
        "FromUserId"                      AS "UserId",
        COUNT(DISTINCT "Id")              AS "Distinct_Upvotes_Given"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
) g
    ON r."UserId" = g."UserId"
JOIN META_KAGGLE.META_KAGGLE.USERS u
    ON r."UserId" = u."Id"
ORDER BY
    r."Distinct_Upvotes_Received" DESC NULLS LAST
LIMIT 3;