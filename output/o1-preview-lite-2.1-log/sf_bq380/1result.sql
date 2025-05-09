WITH UpvotesReceived AS (
    SELECT "ToUserId" AS "UserId", COUNT(*) AS "UpvotesReceived"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    GROUP BY "ToUserId"
),
UpvotesGiven AS (
    SELECT "FromUserId" AS "UserId", COUNT(*) AS "UpvotesGiven"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    GROUP BY "FromUserId"
)
SELECT U."UserName", R."UpvotesReceived", COALESCE(G."UpvotesGiven", 0) AS "UpvotesGiven"
FROM UpvotesReceived R
LEFT JOIN UpvotesGiven G ON R."UserId" = G."UserId"
JOIN "META_KAGGLE"."META_KAGGLE"."USERS" U ON R."UserId" = U."Id"
ORDER BY R."UpvotesReceived" DESC NULLS LAST
LIMIT 3;