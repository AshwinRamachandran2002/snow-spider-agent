-- Task: What was the average number of forum message upvotes received per user in 2019?
WITH UpvotesPerUser AS (
    SELECT "ToUserId", COUNT(*) AS "UpvotesReceived"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    WHERE "VoteDate" BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY "ToUserId"
)
SELECT ROUND(AVG("UpvotesReceived"), 4) AS "AverageUpvotes" FROM UpvotesPerUser;