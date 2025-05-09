WITH
-- total distinct votes each user has RECEIVED
received AS (
    SELECT
        "ToUserId"      AS "UserId",
        COUNT(DISTINCT "Id") AS "ReceivedVotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
-- total distinct votes each user has GIVEN
given AS (
    SELECT
        "FromUserId"    AS "UserId",
        COUNT(DISTINCT "Id") AS "GivenVotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
)

SELECT
    u."UserName",
    r."ReceivedVotes"                           AS "TotalDistinctUpvotesReceived",
    COALESCE(g."GivenVotes", 0)                 AS "TotalDistinctUpvotesGiven"
FROM received r
LEFT JOIN given g
       ON g."UserId" = r."UserId"
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u
       ON u."Id" = r."UserId"
ORDER BY r."ReceivedVotes" DESC NULLS LAST
LIMIT 3;