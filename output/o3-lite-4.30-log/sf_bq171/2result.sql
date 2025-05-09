WITH counts AS (   -- forum up‑votes each user got in 2019
    SELECT "ToUserId",
           COUNT(*) AS upvotes_2019
    FROM   META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE  "VoteDate" BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP  BY "ToUserId"
),
avg_val AS (       -- average 2019 up‑votes per user
    SELECT AVG(upvotes_2019) AS avg_2019_upvotes
    FROM   counts
),
distances AS (     -- absolute distance from that average
    SELECT c."ToUserId",
           c.upvotes_2019,
           ABS(c.upvotes_2019 - a.avg_2019_upvotes) AS dist
    FROM   counts c
           CROSS JOIN avg_val a
),
ranked AS (        -- pick the user(s) closest to the average, tie‑break alphabetically
    SELECT d."ToUserId",
           d.dist,
           ROW_NUMBER() OVER (ORDER BY d.dist, u."UserName") AS rn
    FROM   distances d
           JOIN META_KAGGLE.META_KAGGLE.USERS u
             ON u."Id" = d."ToUserId"
)
SELECT u."UserName" AS username
FROM   ranked r
       JOIN META_KAGGLE.META_KAGGLE.USERS u
         ON u."Id" = r."ToUserId"
WHERE  r.rn = 1;