WITH UpvotesPerUser AS (
    SELECT "ToUserId", COUNT(*) AS "UpvotesReceived"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    WHERE "VoteDate" BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY "ToUserId"
),
AverageUpvotes AS (
    SELECT ROUND(AVG("UpvotesReceived"), 4) AS "AverageUpvotes" FROM UpvotesPerUser
),
UserUpvotesWithDiff AS (
    SELECT UPU."ToUserId", UPU."UpvotesReceived", AU."AverageUpvotes", ABS(UPU."UpvotesReceived" - AU."AverageUpvotes") AS "Diff"
    FROM UpvotesPerUser UPU
    CROSS JOIN AverageUpvotes AU
),
MinDiff AS (
    SELECT MIN("Diff") AS "MinDiff" FROM UserUpvotesWithDiff
)
SELECT U."UserName", UPU."UpvotesReceived", UPU."AverageUpvotes"
FROM UserUpvotesWithDiff UPU
JOIN "META_KAGGLE"."META_KAGGLE"."USERS" U ON UPU."ToUserId" = U."Id"
JOIN MinDiff MD ON UPU."Diff" = MD."MinDiff"
ORDER BY U."UserName" ASC
LIMIT 1;