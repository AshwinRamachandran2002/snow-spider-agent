/*-----------------------------------------------
  Top giver → receiver pair by DISTINCT up-votes
------------------------------------------------*/
WITH pair_counts AS (      -- votes from giver → receiver
    SELECT
        "FromUserId"  AS giver_id,
        "ToUserId"    AS receiver_id,
        COUNT(DISTINCT "ForumMessageId") AS votes_given
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" > 0           -- skip anonymous/system ids
      AND "ToUserId"   > 0
      AND "FromUserId" <> "ToUserId" -- exclude self-votes
    GROUP BY "FromUserId", "ToUserId"
),
bi_counts AS (              -- attach reverse-direction counts
    SELECT
        pc1.giver_id,
        pc1.receiver_id,
        pc1.votes_given                         AS votes_received_by_receiver,
        COALESCE(pc2.votes_given, 0)            AS votes_returned_by_receiver
    FROM pair_counts pc1
    LEFT JOIN pair_counts pc2
           ON pc2.giver_id    = pc1.receiver_id
          AND pc2.receiver_id = pc1.giver_id
),
ranked AS (                 -- rank pairs by required ordering
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY
                 votes_received_by_receiver DESC NULLS LAST,
                 votes_returned_by_receiver DESC NULLS LAST) AS rn
    FROM bi_counts
)
SELECT
    gu."UserName" AS giver_username,
    ru."UserName" AS receiver_username,
    votes_received_by_receiver,
    votes_returned_by_receiver
FROM ranked r
JOIN META_KAGGLE.META_KAGGLE.USERS gu ON gu."Id" = r.giver_id
JOIN META_KAGGLE.META_KAGGLE.USERS ru ON ru."Id" = r.receiver_id
WHERE rn = 1;