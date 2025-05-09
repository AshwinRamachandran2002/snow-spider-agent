WITH votes_2019 AS (
    SELECT
        "ToUserId"      AS "USER_ID",
        COUNT(*)        AS "UPVOTES"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" >= '2019-01-01'
      AND "VoteDate" <  '2020-01-01'
      AND "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
stats AS (
    SELECT AVG("UPVOTES") AS "AVG_UPVOTES"
    FROM votes_2019
),
diffs AS (
    SELECT
        v."USER_ID",
        v."UPVOTES",
        ABS(v."UPVOTES" - s."AVG_UPVOTES") AS "DISTANCE_FROM_AVG"
    FROM votes_2019 v
    CROSS JOIN stats s
)
SELECT
    u."UserName"
FROM diffs d
JOIN META_KAGGLE.META_KAGGLE.USERS u
  ON u."Id" = d."USER_ID"
ORDER BY
    d."DISTANCE_FROM_AVG" ASC,
    u."UserName" ASC
LIMIT 1;