WITH upvotes_2019 AS (           -- total 2019 forum‑message up‑votes each user received
    SELECT
        "ToUserId"         AS "UserId",
        COUNT(*)           AS "UpvoteCount"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY "ToUserId"
),
stats AS (                       -- attach overall average to every user
    SELECT
        u.*,
        AVG("UpvoteCount") OVER () AS "AvgUpvotes"
    FROM upvotes_2019 u
),
diffs AS (                       -- absolute distance to the average
    SELECT
        "UserId",
        ABS("UpvoteCount" - "AvgUpvotes") AS "DiffToAvg"
    FROM stats
),
best_diff AS (                   -- smallest distance found
    SELECT MIN("DiffToAvg") AS "MinDiff" 
    FROM diffs
),
candidates AS (                  -- users whose distance equals the minimum
    SELECT d."UserId"
    FROM diffs d
    JOIN best_diff b ON d."DiffToAvg" = b."MinDiff"
)
SELECT   u."UserName"
FROM     candidates c
JOIN     META_KAGGLE.META_KAGGLE.USERS u
       ON u."Id" = c."UserId"
ORDER BY u."UserName" ASC          -- alphabetically first if there is a tie
LIMIT 1;