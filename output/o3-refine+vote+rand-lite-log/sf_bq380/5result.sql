WITH received AS (
    SELECT
        "ToUserId"                   AS "UserId",
        COUNT(DISTINCT "FromUserId") AS "ReceivedDistinctUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
given AS (
    SELECT
        "FromUserId"                  AS "UserId",
        COUNT(DISTINCT "ForumMessageId") AS "GivenDistinctUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
)
SELECT
    u."UserName"                              AS "username",
    r."ReceivedDistinctUpvotes"               AS "total_distinct_upvotes_received",
    COALESCE(g."GivenDistinctUpvotes", 0)     AS "total_distinct_upvotes_given"
FROM received r
JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = r."UserId"
LEFT JOIN given g
      ON g."UserId" = r."UserId"
ORDER BY r."ReceivedDistinctUpvotes" DESC NULLS LAST, u."UserName"
LIMIT 3;