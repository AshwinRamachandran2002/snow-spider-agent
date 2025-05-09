SELECT 
    fu."UserName" AS "UserName_A",
    tu."UserName" AS "UserName_B",
    a."Upvotes_A_to_B",
    COALESCE(b."Upvotes_B_to_A", 0) AS "Upvotes_B_to_A"
FROM (
    SELECT "FromUserId" AS "UserA", "ToUserId" AS "UserB", COUNT(DISTINCT "ForumMessageId") AS "Upvotes_A_to_B"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    WHERE "FromUserId" <> -1 AND "ToUserId" <> -1
    GROUP BY "FromUserId", "ToUserId"
) a
LEFT JOIN (
    SELECT "FromUserId" AS "UserB", "ToUserId" AS "UserA", COUNT(DISTINCT "ForumMessageId") AS "Upvotes_B_to_A"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    WHERE "FromUserId" <> -1 AND "ToUserId" <> -1
    GROUP BY "FromUserId", "ToUserId"
) b ON a."UserA" = b."UserB" AND a."UserB" = b."UserA"
JOIN "META_KAGGLE"."META_KAGGLE"."USERS" fu ON fu."Id" = a."UserA"
JOIN "META_KAGGLE"."META_KAGGLE"."USERS" tu ON tu."Id" = a."UserB"
ORDER BY a."Upvotes_A_to_B" DESC NULLS LAST, COALESCE(b."Upvotes_B_to_A", 0) DESC NULLS LAST
LIMIT 1;