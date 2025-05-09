WITH pair_counts AS
(
    SELECT
        "FromUserId"   AS "giver_user_id",
        "ToUserId"     AS "receiver_user_id",
        COUNT(DISTINCT "Id") AS "votes_giver_to_receiver"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId", "ToUserId"
),

bidirectional AS
(
    SELECT
        pc."giver_user_id",
        pc."receiver_user_id",
        pc."votes_giver_to_receiver",
        COALESCE(rc."votes_giver_to_receiver", 0) AS "votes_receiver_to_giver"
    FROM pair_counts pc
    LEFT JOIN pair_counts rc
           ON rc."giver_user_id"   = pc."receiver_user_id"
          AND rc."receiver_user_id" = pc."giver_user_id"
)

SELECT
    u_from."UserName" AS "Giver_UserName",
    u_to."UserName"   AS "Receiver_UserName",
    b."votes_giver_to_receiver" AS "Upvotes_Given",
    b."votes_receiver_to_giver" AS "Upvotes_Returned"
FROM bidirectional b
JOIN META_KAGGLE.META_KAGGLE.USERS u_from
     ON u_from."Id" = b."giver_user_id"
JOIN META_KAGGLE.META_KAGGLE.USERS u_to
     ON u_to."Id" = b."receiver_user_id"
ORDER BY
    b."votes_giver_to_receiver" DESC NULLS LAST,
    b."votes_receiver_to_giver" DESC NULLS LAST
LIMIT 1;