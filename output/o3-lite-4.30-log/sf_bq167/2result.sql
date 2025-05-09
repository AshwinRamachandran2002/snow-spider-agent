WITH pair_counts AS (                -- distinct forum‑messages a user up‑voted for another user
    SELECT
        "FromUserId"  AS giver_id,
        "ToUserId"    AS receiver_id,
        COUNT(DISTINCT "ForumMessageId") AS upvotes_given          -- A → B
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId", "ToUserId"
),
pair_with_names AS (                 -- keep only rows where both users have profile rows
    SELECT
        pc.giver_id,
        pc.receiver_id,
        pc.upvotes_given,
        g."UserName" AS giver_username,
        r."UserName" AS receiver_username
    FROM pair_counts pc
    JOIN META_KAGGLE.META_KAGGLE.USERS g ON g."Id" = pc.giver_id
    JOIN META_KAGGLE.META_KAGGLE.USERS r ON r."Id" = pc.receiver_id
),
pair_bidirectional AS (              -- attach reverse‑direction counts
    SELECT
        p1.giver_username    AS upvoter_username,
        p1.receiver_username AS recipient_username,
        CAST(p1.upvotes_given AS NUMBER(38,4))                    AS upvotes_given,
        CAST(COALESCE(p2.upvotes_given, 0) AS NUMBER(38,4))       AS upvotes_returned
    FROM pair_with_names p1
    LEFT JOIN pair_with_names p2
           ON p2.giver_id    = p1.receiver_id
          AND p2.receiver_id = p1.giver_id
),
ranked AS (                           -- rank pairs by received then returned
    SELECT *,
           ROW_NUMBER() OVER (
               ORDER BY upvotes_given DESC,
                        upvotes_returned DESC
           ) AS rn
    FROM pair_bidirectional
)
SELECT
    upvoter_username,
    recipient_username,
    upvotes_given,
    upvotes_returned
FROM ranked
WHERE rn = 1;