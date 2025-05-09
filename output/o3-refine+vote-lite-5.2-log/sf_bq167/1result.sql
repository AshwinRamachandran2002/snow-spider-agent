WITH pair_counts AS (                          -- distinct votes one user gave another
    SELECT
        "FromUserId"   AS giver_id,
        "ToUserId"     AS receiver_id,
        COUNT(DISTINCT "ForumMessageId") AS upvotes_given
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY giver_id, receiver_id
),

paired AS (                                    -- add votes in the reverse direction
    SELECT
        pc.giver_id        AS user_from,
        pc.receiver_id     AS user_to,
        pc.upvotes_given   AS upvotes_from_to,
        COALESCE(rc.upvotes_given, 0) AS upvotes_to_from
    FROM pair_counts pc
    LEFT JOIN pair_counts rc
           ON  rc.giver_id    = pc.receiver_id
           AND rc.receiver_id = pc.giver_id
),

ranked AS (                                    -- rank by most received, then returned
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY upvotes_from_to DESC, upvotes_to_from DESC) AS rn
    FROM paired
)

SELECT
    COALESCE(u_from."UserName", TO_VARCHAR(r.user_from))  AS "Giver_UserName",
    COALESCE(u_to."UserName",   TO_VARCHAR(r.user_to))    AS "Receiver_UserName",
    r.upvotes_from_to                                     AS "Upvotes_Given",
    r.upvotes_to_from                                     AS "Upvotes_Returned"
FROM ranked r
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u_from
       ON u_from."Id" = r.user_from
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u_to
       ON u_to."Id" = r.user_to
WHERE r.rn = 1;