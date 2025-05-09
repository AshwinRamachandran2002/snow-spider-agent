WITH pair_counts AS (                       -- how many votes each sender → recipient pair has
    SELECT 
        "FromUserId" AS sender_id,
        "ToUserId"   AS recipient_id,
        COUNT(*)     AS votes_sender_to_recipient
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY sender_id, recipient_id
),
paired AS (                                 -- add the reciprocal flow (recipient → sender)
    SELECT 
        pc.sender_id,
        pc.recipient_id,
        pc.votes_sender_to_recipient,
        COALESCE(rc.votes_sender_to_recipient,0) AS votes_recipient_to_sender
    FROM pair_counts pc
    LEFT JOIN pair_counts rc
           ON rc.sender_id    = pc.recipient_id
          AND rc.recipient_id = pc.sender_id
),
ranked AS (                                 -- rank pairs by received-from-sender, then returned
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY votes_sender_to_recipient DESC NULLS LAST,
                                      votes_recipient_to_sender DESC NULLS LAST) AS rn
    FROM paired
)
SELECT 
    su."UserName"  AS "SenderUserName",
    ru."UserName"  AS "RecipientUserName",
    votes_sender_to_recipient AS "Votes_Sent",
    votes_recipient_to_sender AS "Votes_Returned"
FROM ranked r
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS su ON su."Id" = r.sender_id
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS ru ON ru."Id" = r.recipient_id
WHERE rn = 1;                               -- show only the top sender → recipient pair