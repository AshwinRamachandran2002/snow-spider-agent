WITH votes_2019 AS (
    SELECT "ToUserId" AS user_id
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" >= '2019-01-01'
      AND "VoteDate" <  '2020-01-01'
),
user_counts AS (
    SELECT
        user_id,
        COUNT(*) AS upvotes_2019
    FROM votes_2019
    GROUP BY user_id
),
avg_upvotes AS (
    SELECT AVG(upvotes_2019) AS avg_cnt
    FROM user_counts
),
user_diffs AS (
    SELECT
        uc.user_id,
        uc.upvotes_2019,
        au.avg_cnt,
        ABS(uc.upvotes_2019 - au.avg_cnt) AS diff_from_avg
    FROM user_counts uc
    CROSS JOIN avg_upvotes au
),
closest_users AS (
    SELECT
        ud.user_id,
        ud.diff_from_avg
    FROM user_diffs ud
    WHERE ud.diff_from_avg = (
        SELECT MIN(diff_from_avg) FROM user_diffs
    )
)
SELECT u."UserName"
FROM closest_users cu
JOIN META_KAGGLE.META_KAGGLE.USERS u
  ON u."Id" = cu.user_id
ORDER BY u."UserName"
LIMIT 1;