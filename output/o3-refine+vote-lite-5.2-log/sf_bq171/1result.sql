WITH yearly_votes AS (
    SELECT 
        "ToUserId"      AS "UserId",
        COUNT(*)        AS "VoteCount"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE EXTRACT(year FROM "VoteDate") = 2019
      AND "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
votes_with_avg AS (
    SELECT
        "UserId",
        "VoteCount",
        AVG("VoteCount") OVER () AS "AvgVote"
    FROM yearly_votes
),
ranked AS (
    SELECT
        u."UserName",
        v."VoteCount",
        v."AvgVote",
        ABS(v."VoteCount" - v."AvgVote") AS "Diff"
    FROM votes_with_avg v
    JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = v."UserId"
)
SELECT "UserName"
FROM ranked
ORDER BY "Diff" ASC, "UserName" ASC
LIMIT 1;