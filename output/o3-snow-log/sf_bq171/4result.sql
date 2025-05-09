WITH upvotes_2019 AS (
    SELECT 
        "ToUserId"          AS "UserId",
        COUNT(*)            AS "UpvoteCount"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE YEAR("VoteDate") = 2019
    GROUP BY "ToUserId"
),
average_val AS (
    SELECT AVG("UpvoteCount") AS "AvgUpvotes"
    FROM upvotes_2019
),
closest_users AS (
    SELECT 
        u."UserName",
        u19."UpvoteCount",
        ABS(u19."UpvoteCount" - av."AvgUpvotes") AS "DiffFromAvg"
    FROM upvotes_2019            u19
    CROSS JOIN average_val       av
    JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = u19."UserId"
)
SELECT "UserName"
FROM closest_users
ORDER BY "DiffFromAvg" ASC, "UserName" ASC
LIMIT 1;