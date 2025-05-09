WITH received AS (      -- how many forum-up-votes each user has RECEIVED
    SELECT
        "ToUserId"      AS "UserId",
        COUNT(*)        AS "ReceivedCnt"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
given AS (              -- how many forum-up-votes each user has GIVEN
    SELECT
        "FromUserId"    AS "UserId",
        COUNT(*)        AS "GivenCnt"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
)
SELECT
    u."UserName",
    r."ReceivedCnt"                                     AS "TotalDistinctUpvotesReceived",
    COALESCE(g."GivenCnt", 0)                           AS "TotalDistinctUpvotesGiven"
FROM received r
JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = r."UserId"
LEFT JOIN given g
      ON g."UserId" = r."UserId"
ORDER BY r."ReceivedCnt" DESC NULLS LAST
LIMIT 3;