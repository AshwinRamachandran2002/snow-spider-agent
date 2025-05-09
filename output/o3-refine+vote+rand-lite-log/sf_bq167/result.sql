WITH vote_counts AS (   -- count how many times each user up‑voted another user
    SELECT
        "FromUserId"           AS from_user_id,
        "ToUserId"             AS to_user_id,
        COUNT(DISTINCT "ForumMessageId") AS vote_cnt            -- distinct up‑votes
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
      AND "ToUserId"   IS NOT NULL
    GROUP BY
        from_user_id,
        to_user_id
),
paired AS (            -- bring the two directions together
    SELECT
        vc1.from_user_id  AS giver_id,
        vc1.to_user_id    AS receiver_id,
        vc1.vote_cnt      AS votes_from_to,                     -- giver → receiver
        COALESCE(vc2.vote_cnt,0) AS votes_to_from               -- receiver → giver
    FROM vote_counts vc1
    LEFT JOIN vote_counts vc2
           ON vc2.from_user_id = vc1.to_user_id
          AND vc2.to_user_id   = vc1.from_user_id
)
SELECT
    u_giver."UserName"    AS "GiverUserName",
    u_recv."UserName"     AS "ReceiverUserName",
    p.votes_from_to       AS "Votes_From_Giver_To_Receiver",
    p.votes_to_from       AS "Votes_From_Receiver_To_Giver"
FROM paired p
JOIN META_KAGGLE.META_KAGGLE.USERS u_giver
     ON u_giver."Id" = p.giver_id
JOIN META_KAGGLE.META_KAGGLE.USERS u_recv
     ON u_recv."Id" = p.receiver_id
ORDER BY
    p.votes_from_to DESC NULLS LAST,
    p.votes_to_from DESC NULLS LAST
LIMIT 1;