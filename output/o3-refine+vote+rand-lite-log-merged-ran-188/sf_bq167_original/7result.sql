WITH pair_counts AS (   -- how many times each user up‑voted another user
    SELECT
        "FromUserId"  AS giver_id,
        "ToUserId"    AS receiver_id,
        COUNT(*)      AS votes_given
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId", "ToUserId"
),
paired_totals AS (      -- attach the reverse direction (returned up‑votes)
    SELECT
        pc.giver_id,
        pc.receiver_id,
        pc.votes_given                     AS votes_received,            -- A → B
        COALESCE(rc.votes_given, 0)        AS votes_returned             -- B → A
    FROM pair_counts pc
    LEFT JOIN pair_counts rc              -- reverse direction
           ON rc.giver_id    = pc.receiver_id
          AND rc.receiver_id = pc.giver_id
),
ranked AS (              -- pick the pair with the largest received count
    SELECT
        u_recv."UserName"  AS "RecipientUserName",
        u_give."UserName"  AS "GiverUserName",
        pt.votes_received  AS "UpvotesReceived",
        pt.votes_returned  AS "UpvotesReturned",
        ROW_NUMBER() OVER (ORDER BY pt.votes_received DESC NULLS LAST,
                                   pt.votes_returned DESC NULLS LAST) AS rn
    FROM paired_totals pt
    JOIN META_KAGGLE.META_KAGGLE.USERS u_give
         ON u_give."Id" = pt.giver_id
    JOIN META_KAGGLE.META_KAGGLE.USERS u_recv
         ON u_recv."Id" = pt.receiver_id
)
SELECT
    "RecipientUserName",
    "GiverUserName",
    "UpvotesReceived",
    "UpvotesReturned"
FROM ranked
WHERE rn = 1;