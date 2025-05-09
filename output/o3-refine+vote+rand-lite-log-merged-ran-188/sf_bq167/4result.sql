WITH pair_counts AS (           -- 1)  count distinct up-votes for every ordered (giver → receiver) pair
    SELECT
        "FromUserId"  AS "giver_id",
        "ToUserId"    AS "receiver_id",
        COUNT(DISTINCT "ForumMessageId") AS "upvotes_given"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId", "ToUserId"
),

reciprocal AS (                 -- 2)  attach the votes that flowed in the opposite direction
    SELECT
        pc."giver_id",
        pc."receiver_id",
        pc."upvotes_given"                                             AS "upvotes_received",
        COALESCE(r."upvotes_given", 0)                                 AS "upvotes_returned"
    FROM pair_counts pc
    LEFT JOIN pair_counts r
           ON r."giver_id"   = pc."receiver_id"
          AND r."receiver_id" = pc."giver_id"
)

SELECT                          -- 3)  bring in user-names and keep only the top pair
       u_recv."UserName"  AS "Recipient_User",
       u_giver."UserName" AS "Giver_User",
       reciprocal."upvotes_received"  AS "Upvotes_Received",
       reciprocal."upvotes_returned"  AS "Upvotes_Returned"
FROM reciprocal
JOIN META_KAGGLE.META_KAGGLE.USERS u_giver
     ON u_giver."Id" = reciprocal."giver_id"
JOIN META_KAGGLE.META_KAGGLE.USERS u_recv
     ON u_recv."Id" = reciprocal."receiver_id"
ORDER BY
       reciprocal."upvotes_received" DESC NULLS LAST,
       reciprocal."upvotes_returned" DESC NULLS LAST
LIMIT 1;