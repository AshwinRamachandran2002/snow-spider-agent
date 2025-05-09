WITH
    -- total distinct forum-message votes each user HAS RECEIVED
    "votes_received" AS (
        SELECT
            "ToUserId"   AS "UserId",
            COUNT(DISTINCT "Id") AS "TotalUpvotesReceived"
        FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
        WHERE "ToUserId" IS NOT NULL
        GROUP BY "ToUserId"
    ),

    -- total distinct forum-message votes each user HAS GIVEN
    "votes_given" AS (
        SELECT
            "FromUserId" AS "UserId",
            COUNT(DISTINCT "Id") AS "TotalUpvotesGiven"
        FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
        WHERE "FromUserId" IS NOT NULL
        GROUP BY "FromUserId"
    )

SELECT
    u."UserName",
    r."TotalUpvotesReceived",
    COALESCE(g."TotalUpvotesGiven", 0) AS "TotalUpvotesGiven"
FROM     "votes_received" r
LEFT JOIN "votes_given"   g ON r."UserId" = g."UserId"
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u ON r."UserId" = u."Id"
ORDER BY r."TotalUpvotesReceived" DESC NULLS LAST
LIMIT 3;