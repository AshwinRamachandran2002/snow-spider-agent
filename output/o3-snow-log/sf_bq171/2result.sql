WITH votes_2019 AS (
    SELECT 
        "ToUserId"                AS user_id,
        COUNT(*)                  AS upvote_count
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" >= '2019-01-01' 
      AND "VoteDate" <  '2020-01-01'
    GROUP BY "ToUserId"
),
avg_up AS (
    SELECT AVG(upvote_count) AS avg_upvotes
    FROM votes_2019
),
diffs AS (
    SELECT 
        v.user_id,
        v.upvote_count,
        a.avg_upvotes,
        ABS(v.upvote_count - a.avg_upvotes) AS diff_to_avg
    FROM votes_2019 v
    CROSS JOIN avg_up a
)
SELECT 
    u."UserName"
FROM diffs d
JOIN META_KAGGLE.META_KAGGLE.USERS u
  ON u."Id" = d.user_id
ORDER BY 
    d.diff_to_avg ASC,
    u."UserName" ASC
LIMIT 1;