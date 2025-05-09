/* Top three users with the most distinct forum up‑votes received */
SELECT
    u."UserName"                                 AS "USERNAME",
    r.received_upvotes                           AS "TOTAL_DISTINCT_UPVOTES_RECEIVED",
    COALESCE(g.given_upvotes, 0)                 AS "TOTAL_DISTINCT_UPVOTES_GIVEN"
FROM (
        /* Distinct up‑votes received (ToUserId) */
        SELECT
            "ToUserId"      AS user_id,
            COUNT(*)        AS received_upvotes
        FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
        WHERE "ToUserId" IS NOT NULL
        GROUP BY "ToUserId"
     ) r
JOIN META_KAGGLE.META_KAGGLE.USERS u
     ON u."Id" = r.user_id
LEFT JOIN (
        /* Distinct up‑votes given (FromUserId) */
        SELECT
            "FromUserId"    AS user_id,
            COUNT(*)        AS given_upvotes
        FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
        WHERE "FromUserId" IS NOT NULL
        GROUP BY "FromUserId"
     ) g
     ON g.user_id = r.user_id
ORDER BY r.received_upvotes DESC NULLS LAST
LIMIT 3;