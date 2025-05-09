WITH messages_2019 AS (
    SELECT "Id", "PostUserId"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES
    WHERE TO_DATE("PostDate", 'MM/DD/YYYY HH24:MI:SS') >= '2019-01-01'
      AND TO_DATE("PostDate", 'MM/DD/YYYY HH24:MI:SS') < '2020-01-01'
),
upvotes_2019 AS (
    SELECT "Id" AS "VoteId", "ForumMessageId"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "VoteDate" >= '2019-01-01' AND "VoteDate" < '2020-01-01'
),
upvotes_per_user AS (
    SELECT m."PostUserId", COUNT(u."VoteId") AS "TotalUpvotes"
    FROM messages_2019 m
    LEFT JOIN upvotes_2019 u ON m."Id" = u."ForumMessageId"
    GROUP BY m."PostUserId"
),
average_upvotes AS (
    SELECT ROUND(AVG("TotalUpvotes"), 4) AS "AverageUpvotes"
    FROM upvotes_per_user
),
differences AS (
    SELECT up."PostUserId", up."TotalUpvotes", av."AverageUpvotes",
           ABS(up."TotalUpvotes" - av."AverageUpvotes") AS "Difference"
    FROM upvotes_per_user up CROSS JOIN average_upvotes av
)
SELECT u."UserName", up."TotalUpvotes" AS "Upvotes_Received", av."AverageUpvotes"
FROM differences d
JOIN upvotes_per_user up ON d."PostUserId" = up."PostUserId"
JOIN average_upvotes av ON 1=1
JOIN META_KAGGLE.META_KAGGLE.USERS u ON d."PostUserId" = u."Id"
WHERE d."Difference" = (
    SELECT MIN("Difference")
    FROM differences
)
ORDER BY u."UserName" ASC
LIMIT 1;