WITH yearly_votes AS (
    /* upvotes each user received in 2019 */
    SELECT
        "ToUserId"    AS "UserId",
        COUNT(*)      AS "Upvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE YEAR("VoteDate") = 2019
      AND "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
stats AS (
    /* attach overall average to every row */
    SELECT
        y."UserId",
        y."Upvotes",
        AVG(y."Upvotes") OVER () AS "AvgUpvotes"
    FROM yearly_votes y
),
diffs AS (
    /* distance of each user’s total from the average */
    SELECT
        "UserId",
        ABS("Upvotes" - "AvgUpvotes") AS "DiffFromAvg"
    FROM stats
)
SELECT
    u."UserName"
FROM diffs d
JOIN META_KAGGLE.META_KAGGLE.USERS u
  ON u."Id" = d."UserId"
ORDER BY
    d."DiffFromAvg" ASC,
    u."UserName" ASC
LIMIT 1;