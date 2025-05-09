WITH received AS (
    SELECT
        "ToUserId"            AS user_id,
        COUNT(DISTINCT "Id")  AS received_upvotes
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "ToUserId"
),
given AS (
    SELECT
        "FromUserId"          AS user_id,
        COUNT(DISTINCT "Id")  AS given_upvotes
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId"
),
combined AS (
    SELECT
        u."UserName",
        r.received_upvotes,
        COALESCE(g.given_upvotes, 0) AS given_upvotes
    FROM received r
    JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = r.user_id
    LEFT JOIN given g
      ON g.user_id = r.user_id
)
SELECT
    "UserName",
    received_upvotes  AS "TotalDistinctUpvotesReceived",
    given_upvotes     AS "TotalDistinctUpvotesGiven"
FROM combined
ORDER BY received_upvotes DESC NULLS LAST
LIMIT 3;