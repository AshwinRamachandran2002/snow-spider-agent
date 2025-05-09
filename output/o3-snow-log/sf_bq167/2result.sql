WITH vote_counts AS (
    SELECT 
        "FromUserId",
        "ToUserId",
        COUNT(*) AS "votes_given"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId", "ToUserId"
),
pair_stats AS (
    SELECT 
        vc."FromUserId" AS "giver_id",
        vc."ToUserId"   AS "receiver_id",
        vc."votes_given",
        COALESCE(rv."votes_given", 0) AS "votes_returned"
    FROM vote_counts vc
    LEFT JOIN vote_counts rv
           ON  vc."FromUserId" = rv."ToUserId"
          AND vc."ToUserId"   = rv."FromUserId"
)
SELECT 
    u_from."UserName" AS "from_user",
    u_to."UserName"   AS "to_user",
    ps."votes_given",
    ps."votes_returned"
FROM pair_stats ps
JOIN META_KAGGLE.META_KAGGLE.USERS u_from
      ON ps."giver_id"    = u_from."Id"
JOIN META_KAGGLE.META_KAGGLE.USERS u_to
      ON ps."receiver_id" = u_to."Id"
ORDER BY ps."votes_given" DESC NULLS LAST,
         ps."votes_returned" DESC NULLS LAST
LIMIT 1;