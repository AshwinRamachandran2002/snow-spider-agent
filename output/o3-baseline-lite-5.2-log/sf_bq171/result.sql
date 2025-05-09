WITH votes_2019 AS (
    SELECT
        "ToUserId" AS user_id
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE EXTRACT(YEAR FROM "VoteDate") = 2019
),
user_counts AS (
    SELECT
        user_id,
        COUNT(*) AS upvotes
    FROM votes_2019
    GROUP BY user_id
),
avg_cte AS (
    SELECT
        AVG(upvotes) AS avg_upvotes
    FROM user_counts
),
diffs AS (
    SELECT
        uc.user_id,
        uc.upvotes,
        ABS(uc.upvotes - a.avg_upvotes) AS diff
    FROM user_counts uc
    CROSS JOIN avg_cte a
),
ranked AS (
    SELECT
        u."UserName",
        d.diff,
        ROW_NUMBER() OVER (ORDER BY d.diff, u."UserName") AS rn
    FROM diffs d
    JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = d.user_id
)
SELECT
    "UserName"
FROM ranked
WHERE rn = 1;