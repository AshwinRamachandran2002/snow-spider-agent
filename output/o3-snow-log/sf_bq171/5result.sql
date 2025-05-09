WITH vote_counts AS (
    -- upvotes each user received in 2019
    SELECT 
        "ToUserId"           AS user_id,
        COUNT(*)             AS upvotes
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" >= '2019-01-01'
      AND "VoteDate" <  '2020-01-01'
      AND "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
closest_to_avg AS (
    -- distance of each user’s upvotes from the overall average
    SELECT 
        vc.user_id,
        vc.upvotes,
        ABS(vc.upvotes - (SELECT AVG(upvotes) FROM vote_counts)) AS diff_from_avg
    FROM vote_counts vc
)
SELECT 
    u."UserName"
FROM closest_to_avg c
JOIN META_KAGGLE.META_KAGGLE.USERS u
  ON u."Id" = c.user_id
ORDER BY 
    c.diff_from_avg ASC,      -- closest to the average first
    u."UserName"      ASC     -- tie-break alphabetically
LIMIT 1;