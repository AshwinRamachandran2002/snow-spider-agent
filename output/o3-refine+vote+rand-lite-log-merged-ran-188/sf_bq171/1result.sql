WITH votes_2019 AS (                           -- up-votes each user received in 2019
    SELECT  "ToUserId",
            COUNT(*) AS votes_cnt
    FROM    META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    WHERE   "VoteDate" >= '2019-01-01'
      AND   "VoteDate" <  '2020-01-01'
    GROUP BY "ToUserId"
),
avg_votes AS (                                 -- overall average
    SELECT AVG(votes_cnt) AS avg_cnt
    FROM   votes_2019
),
diffs AS (                                     -- distance of every user from the average
    SELECT  v."ToUserId",
            v.votes_cnt,
            ABS(v.votes_cnt - a.avg_cnt) AS diff_from_avg
    FROM    votes_2019 v
    CROSS JOIN avg_votes a
),
min_diff AS (                                  -- smallest distance
    SELECT MIN(diff_from_avg) AS min_diff
    FROM   diffs
)
SELECT  u."UserName",                          -- alphabetically-first user among ties
        d.votes_cnt         AS votes_2019,
        d.diff_from_avg
FROM    diffs d
JOIN    min_diff m  ON d.diff_from_avg = m.min_diff
JOIN    META_KAGGLE.META_KAGGLE."USERS" u
        ON u."Id" = d."ToUserId"
ORDER BY u."UserName"
LIMIT 1;