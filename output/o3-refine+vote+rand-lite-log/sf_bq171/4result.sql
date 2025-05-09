WITH user_votes AS (
    SELECT
        "ToUserId"              AS user_id,
        COUNT(*)                AS upvotes_2019
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" >= '2019-01-01'
      AND "VoteDate" <  '2020-01-01'
    GROUP BY "ToUserId"
),
avg_val AS (
    SELECT AVG(upvotes_2019) AS avg_upvotes
    FROM user_votes
),
with_diff AS (
    SELECT
        u."UserName",
        uv.upvotes_2019,
        ABS(uv.upvotes_2019 - a.avg_upvotes) AS diff_to_avg
    FROM user_votes uv
    CROSS JOIN avg_val a
    JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = uv.user_id
)
SELECT "UserName"
FROM with_diff
ORDER BY diff_to_avg ASC, "UserName" ASC
LIMIT 1;