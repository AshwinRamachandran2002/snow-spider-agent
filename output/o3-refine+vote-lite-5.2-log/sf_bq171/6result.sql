WITH votes_2019 AS (
    SELECT
        "ToUserId",
        COUNT(*) AS "cnt"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
      AND "VoteDate" >= '2019-01-01'
      AND "VoteDate" <  '2020-01-01'
    GROUP BY "ToUserId"
),
avg_cnt AS (
    SELECT AVG("cnt") AS "avg_cnt"
    FROM votes_2019
)
SELECT
    u."UserName"
FROM votes_2019 v
CROSS JOIN avg_cnt a
JOIN META_KAGGLE.META_KAGGLE.USERS u
  ON u."Id" = v."ToUserId"
ORDER BY
    ABS(v."cnt" - a."avg_cnt") ASC,
    u."UserName" ASC
LIMIT 1;