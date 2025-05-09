WITH vote_counts AS (           -- 1. total up-votes for every ordered pair (exclude anonymous -1)
    SELECT  "FromUserId"  AS "giver_id",
            "ToUserId"    AS "receiver_id",
            COUNT(*)      AS "giver_to_receiver"
    FROM    META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE   "FromUserId"  > 0          -- keep real Kaggle users only
      AND   "ToUserId"    > 0
    GROUP BY "FromUserId", "ToUserId"
),
paired AS (                     -- 2. bring the reverse direction alongside
    SELECT  vc1."giver_id",
            vc1."receiver_id",
            vc1."giver_to_receiver",
            COALESCE(vc2."giver_to_receiver",0) AS "receiver_to_giver"
    FROM    vote_counts vc1
    LEFT JOIN vote_counts vc2
           ON vc1."giver_id"    = vc2."receiver_id"
          AND vc1."receiver_id" = vc2."giver_id"
)
SELECT  u1."UserName" AS "giver_username",
        u2."UserName" AS "receiver_username",
        p."giver_to_receiver",
        p."receiver_to_giver"
FROM    paired p
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u1 ON u1."Id" = p."giver_id"
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u2 ON u2."Id" = p."receiver_id"
ORDER BY p."giver_to_receiver" DESC NULLS LAST,
         p."receiver_to_giver" DESC NULLS LAST
LIMIT 1;