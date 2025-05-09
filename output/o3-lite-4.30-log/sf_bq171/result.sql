WITH per_user AS (
    SELECT 
        "ToUserId" AS user_id,
        COUNT(*)   AS vote_cnt
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" >= '2019-01-01'
      AND "VoteDate" <  '2020-01-01'
    GROUP BY "ToUserId"
),
avg_tbl AS (
    SELECT AVG(vote_cnt) AS avg_cnt
    FROM per_user
),
ranked AS (
    SELECT
        u."UserName"                              AS username,
        ABS(p.vote_cnt - a.avg_cnt)               AS diff_from_avg
    FROM per_user p
    CROSS JOIN avg_tbl a
    JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = p.user_id
)
SELECT username
FROM ranked
ORDER BY diff_from_avg ASC, username ASC
LIMIT 1;