/* ------------------------------------------------------------
   Find the user-pair where one Kaggle user has given another
   the most forum-message up-votes, and show how many were
   returned in the opposite direction.
-------------------------------------------------------------*/
WITH pair_votes AS (          -- vote counts in one direction
    SELECT
        "FromUserId"                    AS giver_id,
        "ToUserId"                      AS receiver_id,
        COUNT(*)                        AS votes_giver_to_receiver
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY giver_id, receiver_id
),
paired AS (                   -- add the reverse-direction count
    SELECT
        pv.giver_id,
        pv.receiver_id,
        pv.votes_giver_to_receiver,
        COALESCE(rv.votes_giver_to_receiver,0) 
            AS votes_receiver_to_giver
    FROM pair_votes pv
    LEFT JOIN pair_votes rv
           ON  rv.giver_id    = pv.receiver_id
           AND rv.receiver_id = pv.giver_id
),
with_names AS (               -- keep only real users & attach names
    SELECT
        uf."UserName"                        AS giver_username,
        ut."UserName"                        AS receiver_username,
        p.votes_giver_to_receiver,
        p.votes_receiver_to_giver
    FROM paired p
    JOIN META_KAGGLE.META_KAGGLE.USERS uf
         ON uf."Id" = p.giver_id
    JOIN META_KAGGLE.META_KAGGLE.USERS ut
         ON ut."Id" = p.receiver_id
)
SELECT
    giver_username,
    receiver_username,
    votes_giver_to_receiver  AS votes_given,
    votes_receiver_to_giver  AS votes_returned
FROM with_names
ORDER BY
    votes_giver_to_receiver DESC NULLS LAST,
    votes_receiver_to_giver DESC NULLS LAST
LIMIT 1;