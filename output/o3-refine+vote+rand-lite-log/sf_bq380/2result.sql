WITH
-- how many distinct up‑votes each user has RECEIVED
received AS (
    SELECT
        "ToUserId"                             AS "UserId",
        COUNT(DISTINCT "Id")                   AS "ReceivedCnt"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),

-- how many distinct up‑votes each user has GIVEN
given AS (
    SELECT
        "FromUserId"                           AS "UserId",
        COUNT(DISTINCT "Id")                   AS "GivenCnt"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
),

-- merge the two aggregates
combined AS (
    SELECT
        r."UserId",
        r."ReceivedCnt",
        COALESCE(g."GivenCnt",0)               AS "GivenCnt"
    FROM received r
    LEFT JOIN given g
           ON r."UserId" = g."UserId"
)

-- pick the top 3 by up‑votes received and show usernames
SELECT
    u."UserName"                              AS "username",
    c."ReceivedCnt"                           AS "upvotes_received",
    c."GivenCnt"                              AS "upvotes_given"
FROM combined c
JOIN META_KAGGLE.META_KAGGLE.USERS u
     ON c."UserId" = u."Id"
ORDER BY c."ReceivedCnt" DESC NULLS LAST,
         u."UserName" ASC
LIMIT 3;