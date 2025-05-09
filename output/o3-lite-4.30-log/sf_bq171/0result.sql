WITH per_user AS (
    SELECT 
        "ToUserId",
        COUNT(*) AS upvotes_2019
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" >= '2019-01-01'
      AND "VoteDate" <  '2020-01-01'
    GROUP BY "ToUserId"
),
avg_val AS (
    SELECT AVG(upvotes_2019) AS avg_upvotes FROM per_user
),
scored AS (
    SELECT
        p."ToUserId",
        ABS(p.upvotes_2019 - a.avg_upvotes) AS diff_from_avg
    FROM per_user p
    CROSS JOIN avg_val a
),
ranked AS (
    SELECT
        u."UserName" AS username,
        ROW_NUMBER() OVER (ORDER BY s.diff_from_avg ASC, u."UserName" ASC) AS rn
    FROM scored s
    JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = s."ToUserId"
)
SELECT username
FROM ranked
WHERE rn = 1;