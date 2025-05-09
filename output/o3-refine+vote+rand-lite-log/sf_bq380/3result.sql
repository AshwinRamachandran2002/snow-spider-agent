WITH received AS (      -- votes each user HAS RECEIVED
    SELECT
        "ToUserId"               AS "UserId",
        COUNT(DISTINCT "Id")     AS "received_votes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
given AS (         -- votes each user HAS GIVEN
    SELECT
        "FromUserId"             AS "UserId",
        COUNT(DISTINCT "Id")     AS "given_votes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
),
combined AS (      -- merge the two summaries
    SELECT
        r."UserId",
        r."received_votes",
        COALESCE(g."given_votes", 0) AS "given_votes"
    FROM received r
    LEFT JOIN given g
           ON r."UserId" = g."UserId"
)
SELECT
    u."UserName"                  AS "username",
    c."received_votes"            AS "total_distinct_upvotes_received",
    c."given_votes"               AS "total_distinct_upvotes_given"
FROM combined       c
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u
       ON c."UserId" = u."Id"
ORDER BY
    c."received_votes" DESC NULLS LAST,
    u."UserName"
LIMIT 3;