WITH one_way AS (
    -- count how many votes each user (giver) has cast for another user (receiver)
    SELECT 
        "FromUserId"  AS "giver_id",
        "ToUserId"    AS "receiver_id",
        COUNT(*)      AS "votes_giver_to_receiver"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    GROUP BY "FromUserId", "ToUserId"
),
two_way AS (
    -- bring in the reverse direction (receiver → giver) counts
    SELECT
        a."giver_id",
        a."receiver_id",
        a."votes_giver_to_receiver",
        COALESCE(b."votes_giver_to_receiver", 0) AS "votes_receiver_to_giver"
    FROM one_way a
    LEFT JOIN one_way b
           ON a."giver_id"   = b."receiver_id"
          AND a."receiver_id" = b."giver_id"
)
SELECT
    gu."UserName" AS "giver_user",
    ru."UserName" AS "receiver_user",
    t."votes_giver_to_receiver",
    t."votes_receiver_to_giver"
FROM two_way t
JOIN META_KAGGLE.META_KAGGLE."USERS" gu
     ON t."giver_id" = gu."Id"
JOIN META_KAGGLE.META_KAGGLE."USERS" ru
     ON t."receiver_id" = ru."Id"
ORDER BY 
    t."votes_giver_to_receiver" DESC NULLS LAST,
    t."votes_receiver_to_giver" DESC NULLS LAST
LIMIT 1;