WITH "RECEIVED" AS (    -- distinct up‑votes each user has received
    SELECT 
        "ToUserId"                    AS "UserId",
        COUNT(DISTINCT "FromUserId")  AS "DistinctUpvotesReceived"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    GROUP BY "ToUserId"
),
"GIVEN" AS (           -- distinct up‑votes each user has given
    SELECT
        "FromUserId"                 AS "UserId",
        COUNT(DISTINCT "ToUserId")   AS "DistinctUpvotesGiven"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    GROUP BY "FromUserId"
)
SELECT
    u."UserName"                                           AS "Username",
    r."DistinctUpvotesReceived",
    COALESCE(g."DistinctUpvotesGiven", 0)                  AS "DistinctUpvotesGiven"
FROM "RECEIVED" r
LEFT JOIN "GIVEN" g
       ON r."UserId" = g."UserId"
LEFT JOIN META_KAGGLE.META_KAGGLE."USERS" u
       ON u."Id" = r."UserId"
ORDER BY
    r."DistinctUpvotesReceived" DESC NULLS LAST,
    r."UserId" ASC
FETCH FIRST 3 ROWS ONLY;