-- Whose forum‑message up‑votes are closest to the 2019 average?
WITH per_user AS (           -- 1.  Count 2019 up‑votes per recipient
    SELECT 
        "ToUserId",
        COUNT(*) AS "upvote_count"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    WHERE "VoteDate" >= '2019-01-01'
      AND "VoteDate" <  '2020-01-01'
    GROUP BY "ToUserId"
),
avg_val AS (                 -- 2.  Compute the overall average
    SELECT AVG("upvote_count") AS "avg_upvotes"
    FROM   per_user
),
distances AS (               -- 3.  Distance of each user from the average
    SELECT 
        p."ToUserId",
        p."upvote_count",
        ABS(p."upvote_count" - a."avg_upvotes") AS "distance_from_avg"
    FROM per_user p
    CROSS JOIN avg_val a
)
SELECT 
    u."UserName",            -- final answer: user closest to the average
    d."upvote_count",
    d."distance_from_avg"
FROM distances d
JOIN META_KAGGLE.META_KAGGLE."USERS" u
  ON u."Id" = d."ToUserId"
ORDER BY 
    d."distance_from_avg" ASC,   -- closest first
    u."UserName"          ASC    -- tie‑breaker: alphabetically first
LIMIT 1;