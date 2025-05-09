WITH pair_counts AS (        -- how many times one user up‑voted another
    SELECT
        "FromUserId"  AS "giver_id",
        "ToUserId"    AS "receiver_id",
        COUNT(DISTINCT "ForumMessageId") AS "votes_given"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
      AND "ToUserId"   IS NOT NULL
    GROUP BY
        "FromUserId",
        "ToUserId"
),

paired_totals AS (           -- include votes sent in the reverse direction
    SELECT
        pc1."giver_id",
        pc1."receiver_id",
        pc1."votes_given"                       AS "upvotes_received",
        COALESCE(pc2."votes_given", 0)          AS "upvotes_returned"
    FROM pair_counts pc1
    LEFT JOIN pair_counts pc2
           ON pc2."giver_id"    = pc1."receiver_id"
          AND pc2."receiver_id" = pc1."giver_id"
),

top_pair AS (                -- pick the pair with the most received, then most returned
    SELECT *
    FROM paired_totals
    ORDER BY "upvotes_received" DESC,
             "upvotes_returned" DESC
    LIMIT 1
)

SELECT
    u1."UserName" AS "User_A",
    u2."UserName" AS "User_B",
    tp."upvotes_received"  AS "upvotes_A_to_B",
    tp."upvotes_returned"  AS "upvotes_B_to_A"
FROM top_pair tp
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u1 ON u1."Id" = tp."giver_id"
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u2 ON u2."Id" = tp."receiver_id";