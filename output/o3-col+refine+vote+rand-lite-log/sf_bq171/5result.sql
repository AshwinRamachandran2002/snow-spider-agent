/* Whose forum-message up-votes are closest to the 2019 average?
   – break ties by alphabetical user-name */
WITH votes_2019 AS (
    SELECT "ToUserId"                       AS "UserId",
           COUNT(*)                         AS "Votes2019"
    FROM   META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE  EXTRACT(year FROM "VoteDate") = 2019
    GROUP  BY "ToUserId"
),
avg_cte AS (
    SELECT AVG("Votes2019") AS "AvgVotes2019"
    FROM   votes_2019
),
distances AS (
    SELECT v."UserId",
           v."Votes2019",
           ABS(v."Votes2019" - a."AvgVotes2019") AS "DistFromAvg"
    FROM   votes_2019 v
    CROSS  JOIN avg_cte   a
)
SELECT u."UserName",
       d."Votes2019",
       d."DistFromAvg"
FROM   distances d
JOIN   META_KAGGLE.META_KAGGLE.USERS u
       ON u."Id" = d."UserId"
ORDER  BY d."DistFromAvg" ASC,
          u."UserName"   ASC
LIMIT  1;