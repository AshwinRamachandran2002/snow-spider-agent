WITH "user_votes_2019" AS (
    SELECT
        "ToUserId"                          AS "UserId",
        COUNT(*)                            AS "Votes2019"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    WHERE DATE_PART('year', "VoteDate") = 2019
      AND "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
"avg_votes" AS (
    SELECT AVG("Votes2019") AS "AvgVotes2019"
    FROM "user_votes_2019"
),
"closest" AS (
    SELECT
        u."UserName",
        v."Votes2019",
        ABS(v."Votes2019" - a."AvgVotes2019") AS "DiffFromAvg"
    FROM "user_votes_2019" v
    CROSS JOIN "avg_votes" a
    JOIN META_KAGGLE.META_KAGGLE."USERS" u
      ON u."Id" = v."UserId"
)
SELECT "UserName"
FROM "closest"
ORDER BY "DiffFromAvg" ASC, "UserName" ASC
LIMIT 1;