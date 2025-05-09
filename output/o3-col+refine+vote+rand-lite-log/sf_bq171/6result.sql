WITH user_counts AS (
    SELECT 
        "ToUserId",
        COUNT(*) AS upvotes_2019
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY "ToUserId"
),
avg_cte AS (
    SELECT 
        AVG(upvotes_2019) AS avg_upvotes_2019
    FROM user_counts
)
SELECT 
    u."UserName",
    uc.upvotes_2019,
    a.avg_upvotes_2019,
    ABS(uc.upvotes_2019 - a.avg_upvotes_2019) AS abs_gap
FROM user_counts uc
JOIN META_KAGGLE.META_KAGGLE.USERS u
     ON u."Id" = uc."ToUserId",
     avg_cte a
ORDER BY 
    abs_gap ASC,
    u."UserName" ASC
LIMIT 1;