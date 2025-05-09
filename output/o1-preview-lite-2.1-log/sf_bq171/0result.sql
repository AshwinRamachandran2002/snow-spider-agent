WITH UpvotesPerUser AS (
    SELECT "ToUserId", COUNT(*) AS "UpvotesReceived"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    WHERE "VoteDate" >= DATE '2019-01-01' AND "VoteDate" < DATE '2020-01-01'
    GROUP BY "ToUserId"
),
AverageUpvotes AS (
    SELECT ROUND(AVG("UpvotesReceived"), 4) AS "AvgUpvotes"
    FROM UpvotesPerUser
),
UserUpvotes AS (
    SELECT
        u."UserName",
        up."UpvotesReceived",
        avg."AvgUpvotes",
        ABS(up."UpvotesReceived" - avg."AvgUpvotes") AS "DifferenceFromAverage"
    FROM UpvotesPerUser up
    JOIN "META_KAGGLE"."META_KAGGLE"."USERS" u ON up."ToUserId" = u."Id"
    CROSS JOIN AverageUpvotes avg
)
SELECT "UserName", "UpvotesReceived" AS "Upvotes_Received", "AvgUpvotes" AS "Average_Upvotes"
FROM UserUpvotes
ORDER BY "DifferenceFromAverage" ASC, "UserName" ASC
LIMIT 1;