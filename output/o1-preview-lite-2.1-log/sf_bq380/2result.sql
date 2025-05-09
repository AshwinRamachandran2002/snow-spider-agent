SELECT
    u."UserName",
    COALESCE(received."UpvotesReceived", 0) AS "Upvotes_Received",
    COALESCE(given."UpvotesGiven", 0) AS "Upvotes_Given"
FROM
    "META_KAGGLE"."META_KAGGLE"."USERS" u
LEFT JOIN (
    SELECT "ToUserId", COUNT(*) AS "UpvotesReceived"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    GROUP BY "ToUserId"
) received ON u."Id" = received."ToUserId"
LEFT JOIN (
    SELECT "FromUserId", COUNT(*) AS "UpvotesGiven"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    GROUP BY "FromUserId"
) given ON u."Id" = given."FromUserId"
WHERE received."UpvotesReceived" IS NOT NULL
ORDER BY received."UpvotesReceived" DESC NULLS LAST
LIMIT 3;