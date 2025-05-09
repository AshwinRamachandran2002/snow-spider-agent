WITH votes_received AS (
    SELECT
        "ToUserId"                                   AS "UserId",
        COUNT(DISTINCT "Id")                         AS "ReceivedUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
votes_given AS (
    SELECT
        "FromUserId"                                 AS "UserId",
        COUNT(DISTINCT "Id")                         AS "GivenUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
),
combined AS (
    SELECT
        u."UserName",
        r."ReceivedUpvotes",
        COALESCE(g."GivenUpvotes", 0)                AS "GivenUpvotes"
    FROM votes_received r
    LEFT JOIN votes_given g
           ON r."UserId" = g."UserId"
    LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u
           ON r."UserId" = u."Id"
)
SELECT
    "UserName"          AS "username",
    "ReceivedUpvotes"   AS "total_distinct_upvotes_received",
    "GivenUpvotes"      AS "total_distinct_upvotes_given"
FROM combined
ORDER BY "ReceivedUpvotes" DESC NULLS LAST
LIMIT 3;