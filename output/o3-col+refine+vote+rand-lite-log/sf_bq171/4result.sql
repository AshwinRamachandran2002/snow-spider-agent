WITH user_votes AS (           -- 1. total 2019 up-votes each receiver got
    SELECT
        "ToUserId"       AS "UserId",
        COUNT(*)         AS "upvotes_2019"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" >= '2019-01-01'
      AND "VoteDate" <  '2020-01-01'
    GROUP BY "ToUserId"
),
avg_val AS (                    -- 2. overall average of those totals
    SELECT AVG("upvotes_2019") AS "avg_upvotes_2019"
    FROM   user_votes
),
distance_calc AS (              -- 3. absolute distance from the average
    SELECT
        uv."UserId",
        uv."upvotes_2019",
        ABS(uv."upvotes_2019" - a."avg_upvotes_2019") AS "distance_to_avg"
    FROM user_votes uv
    CROSS JOIN avg_val a
)
SELECT                           -- 4. user closest to the average
    us."UserName",
    dc."upvotes_2019",
    dc."distance_to_avg"
FROM distance_calc dc
JOIN META_KAGGLE.META_KAGGLE.USERS us
  ON us."Id" = dc."UserId"
ORDER BY
    dc."distance_to_avg" ASC,    -- smallest distance first
    us."UserName"        ASC     -- alphabetical tiebreaker
LIMIT 1;