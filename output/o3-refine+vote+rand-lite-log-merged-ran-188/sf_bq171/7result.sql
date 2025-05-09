WITH user_votes AS (               -- 1. how many up-votes each recipient got in 2019
    SELECT 
        "ToUserId",
        COUNT(*) AS vote_cnt_2019
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY "ToUserId"
),
avg_val AS (                       -- 2. overall 2019 average
    SELECT AVG(vote_cnt_2019) AS avg_votes_2019
    FROM user_votes
),
dist_calc AS (                     -- 3. distance of every user’s count from the average
    SELECT 
        uv."ToUserId",
        uv.vote_cnt_2019,
        ABS(uv.vote_cnt_2019 - av.avg_votes_2019) AS dist_to_avg
    FROM user_votes uv
    CROSS JOIN avg_val av
)
SELECT                              -- 4. pick the closest; break ties alphabetically
    u."UserName",
    dc.vote_cnt_2019,
    dc.dist_to_avg
FROM dist_calc dc
JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = dc."ToUserId"
ORDER BY dc.dist_to_avg ASC, u."UserName" ASC
LIMIT 1;