WITH votes_2019 AS (           -- all forum-message up-votes cast in 2019
    SELECT "ToUserId" AS user_id
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" BETWEEN '2019-01-01' AND '2019-12-31'
),
user_counts AS (               -- up-vote count per recipient
    SELECT user_id,
           COUNT(*) AS upvotes
    FROM votes_2019
    GROUP BY user_id
),
avg_val AS (                   -- overall average of those counts
    SELECT AVG(upvotes) AS avg_upvotes
    FROM user_counts
),
diffs AS (                     -- distance of each user’s count from the average
    SELECT uc.user_id,
           uc.upvotes,
           ABS(uc.upvotes - av.avg_upvotes) AS diff
    FROM user_counts uc
    CROSS JOIN avg_val av
),
min_diff AS (                  -- smallest distance
    SELECT MIN(diff) AS min_diff
    FROM diffs
),
candidates AS (                -- everyone whose distance equals the minimum
    SELECT d.user_id
    FROM diffs d, min_diff m
    WHERE d.diff = m.min_diff
)
SELECT u."UserName"
FROM candidates c
JOIN META_KAGGLE.META_KAGGLE.USERS u
  ON u."Id" = c.user_id
ORDER BY u."UserName"          -- alphabetically first in case of a tie
LIMIT 1;