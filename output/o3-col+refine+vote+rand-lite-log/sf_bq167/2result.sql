WITH pair_counts AS (           -- votes each user gave another
    SELECT
        "FromUserId" AS giver_id,
        "ToUserId"   AS receiver_id,
        COUNT(DISTINCT "ForumMessageId") AS given_votes
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    GROUP BY "FromUserId", "ToUserId"
),
mutual AS (                     -- attach reverse-direction votes
    SELECT
        pc.giver_id,
        pc.receiver_id,
        pc.given_votes,
        COALESCE(pcb.given_votes, 0) AS returned_votes
    FROM pair_counts pc
    LEFT JOIN pair_counts pcb
           ON pcb.giver_id    = pc.receiver_id
          AND pcb.receiver_id = pc.giver_id
)
SELECT
    COALESCE(ug."UserName", TO_VARCHAR(m.giver_id))    AS "giver_username",
    COALESCE(ur."UserName", TO_VARCHAR(m.receiver_id)) AS "receiver_username",
    m.given_votes      AS "votes_given",
    m.returned_votes   AS "votes_returned"
FROM       mutual m
LEFT JOIN  META_KAGGLE.META_KAGGLE."USERS" ug ON ug."Id" = m.giver_id
LEFT JOIN  META_KAGGLE.META_KAGGLE."USERS" ur ON ur."Id" = m.receiver_id
ORDER BY   m.given_votes DESC NULLS LAST,
           m.returned_votes DESC NULLS LAST
LIMIT 1;