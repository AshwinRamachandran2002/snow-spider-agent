WITH pair_counts AS (   -- how many distinct votes every giver sent to each receiver
    SELECT
        "FromUserId"  AS giver_id,
        "ToUserId"    AS receiver_id,
        COUNT(DISTINCT "Id") AS votes_given
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY giver_id, receiver_id
),
mutual AS (             -- add the reciprocal vote count (if any)
    SELECT
        pc1.giver_id  AS user1_id,
        pc1.receiver_id AS user2_id,
        pc1.votes_given            AS votes_user1_to_user2,
        COALESCE(pc2.votes_given,0) AS votes_user2_to_user1
    FROM pair_counts pc1
    LEFT JOIN pair_counts pc2
           ON pc2.giver_id   = pc1.receiver_id
          AND pc2.receiver_id = pc1.giver_id
),
top_pair AS (           -- keep the pair with the largest one-way total (tie-break on return)
    SELECT *
    FROM   mutual
    ORDER  BY votes_user1_to_user2 DESC NULLS LAST,
              votes_user2_to_user1 DESC NULLS LAST
    LIMIT  1
)
SELECT
    u1."UserName" AS "GIVER_USERNAME",
    u2."UserName" AS "RECEIVER_USERNAME",
    top_pair.votes_user1_to_user2 AS "VOTES_RECEIVED",
    top_pair.votes_user2_to_user1 AS "VOTES_RETURNED"
FROM   top_pair
JOIN   META_KAGGLE.META_KAGGLE.USERS u1 ON u1."Id" = top_pair.user1_id
JOIN   META_KAGGLE.META_KAGGLE.USERS u2 ON u2."Id" = top_pair.user2_id;