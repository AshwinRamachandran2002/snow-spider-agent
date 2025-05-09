WITH per_user AS (          -- count up‑votes received by each user in 2019
    SELECT
        "ToUserId"                                 AS "UserId",
        COUNT(*)                                   AS "Upvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE YEAR("VoteDate") = 2019
    GROUP BY "ToUserId"
),
avg_val AS (                -- overall average of 2019 up‑votes
    SELECT AVG("Upvotes") AS "AvgUpvotes"
    FROM per_user
),
diffs AS (                  -- distance from the average for every user
    SELECT
        u."UserName",
        p."Upvotes",
        ABS(p."Upvotes" - a."AvgUpvotes") AS "Diff"
    FROM per_user p
    CROSS JOIN avg_val a
    JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = p."UserId"
)
SELECT
    "UserName"
FROM diffs
ORDER BY
    "Diff" ASC,             -- closest to the average
    "UserName" ASC          -- tie‑breaker: alphabetically
LIMIT 1;