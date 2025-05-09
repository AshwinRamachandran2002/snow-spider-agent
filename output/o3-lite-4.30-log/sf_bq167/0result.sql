WITH pair_counts AS (
    SELECT
        "FromUserId" AS "giver",
        "ToUserId"   AS "receiver",
        COUNT(DISTINCT "ForumMessageId") AS "votes_forward"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    GROUP BY "FromUserId", "ToUserId"
), paired AS (
    SELECT
        pc1."giver",
        pc1."receiver",
        pc1."votes_forward",
        COALESCE(pc2."votes_forward", 0) AS "votes_back"
    FROM pair_counts pc1
    LEFT JOIN pair_counts pc2
        ON pc1."giver"    = pc2."receiver"
       AND pc1."receiver" = pc2."giver"
)
SELECT
    ug."UserName" AS "upvoter_username",
    ur."UserName" AS "recipient_username",
    TO_DECIMAL(p."votes_forward",38,4) AS "upvotes_given",
    TO_DECIMAL(p."votes_back",38,4)    AS "upvotes_returned"
FROM paired p
JOIN "META_KAGGLE"."META_KAGGLE"."USERS" ug ON p."giver"    = ug."Id"
JOIN "META_KAGGLE"."META_KAGGLE"."USERS" ur ON p."receiver" = ur."Id"
ORDER BY p."votes_forward" DESC, p."votes_back" DESC
LIMIT 1;