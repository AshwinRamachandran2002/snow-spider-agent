WITH agg AS (  -- distinct up-votes passed from one user to another
    SELECT
        "FromUserId",
        "ToUserId",
        COUNT(DISTINCT "ForumMessageId") AS "given_cnt"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId", "ToUserId"
),
paired AS (    -- join each direction of the pair to see what was returned
    SELECT
        a."FromUserId"                       AS "giver_id",
        a."ToUserId"                         AS "receiver_id",
        a."given_cnt"                        AS "upvotes_received_from_giver",
        COALESCE(b."given_cnt", 0)           AS "upvotes_returned_by_receiver"
    FROM agg a
    LEFT JOIN agg b
           ON a."FromUserId" = b."ToUserId"
          AND a."ToUserId"   = b."FromUserId"
)
SELECT
    giver."UserName"  AS "giver_name",
    recv."UserName"   AS "receiver_name",
    paired."upvotes_received_from_giver",
    paired."upvotes_returned_by_receiver"
FROM paired
JOIN META_KAGGLE.META_KAGGLE.USERS giver
     ON giver."Id" = paired."giver_id"
JOIN META_KAGGLE.META_KAGGLE.USERS recv
     ON recv."Id"  = paired."receiver_id"
ORDER BY
    paired."upvotes_received_from_giver" DESC NULLS LAST,
    paired."upvotes_returned_by_receiver" DESC NULLS LAST
LIMIT 1;