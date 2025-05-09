SELECT
    u1."UserName" AS "User1",
    u2."UserName" AS "User2",
    counts."UpvotesFromUser1ToUser2",
    COALESCE(reverse_counts."UpvotesFromUser2ToUser1", 0) AS "UpvotesFromUser2ToUser1"
FROM (
    SELECT "FromUserId", "ToUserId", COUNT(*) AS "UpvotesFromUser1ToUser2"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL AND "ToUserId" IS NOT NULL
    GROUP BY "FromUserId", "ToUserId"
) counts
LEFT JOIN (
    SELECT "FromUserId", "ToUserId", COUNT(*) AS "UpvotesFromUser2ToUser1"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL AND "ToUserId" IS NOT NULL
    GROUP BY "FromUserId", "ToUserId"
) reverse_counts
ON counts."FromUserId" = reverse_counts."ToUserId" AND counts."ToUserId" = reverse_counts."FromUserId"
JOIN META_KAGGLE.META_KAGGLE.USERS u1 ON counts."FromUserId" = u1."Id"
JOIN META_KAGGLE.META_KAGGLE.USERS u2 ON counts."ToUserId" = u2."Id"
ORDER BY (counts."UpvotesFromUser1ToUser2" + COALESCE(reverse_counts."UpvotesFromUser2ToUser1", 0)) DESC NULLS LAST
LIMIT 1;