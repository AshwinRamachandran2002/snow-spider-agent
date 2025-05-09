WITH
-- how many votes each user (sender) has given to another user (receiver)
FORWARD AS (
    SELECT
        "FromUserId"  AS "SENDER_ID",
        "ToUserId"    AS "RECEIVER_ID",
        COUNT(*)      AS "VOTES_GIVEN"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId", "ToUserId"
),

-- how many votes went the opposite way (receiver back to sender)
REVERSE AS (
    SELECT
        "ToUserId"    AS "SENDER_ID",   -- swap the directions
        "FromUserId"  AS "RECEIVER_ID",
        COUNT(*)      AS "VOTES_RETURNED"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "ToUserId", "FromUserId"
),

-- combine forward and reverse counts
PAIR_COUNTS AS (
    SELECT
        F."SENDER_ID",
        F."RECEIVER_ID",
        F."VOTES_GIVEN"                       AS "VOTES_FROM_S_TO_R",
        COALESCE(R."VOTES_RETURNED", 0)       AS "VOTES_FROM_R_TO_S"
    FROM FORWARD F
    LEFT JOIN REVERSE R
           ON  F."SENDER_ID"   = R."SENDER_ID"
          AND F."RECEIVER_ID" = R."RECEIVER_ID"
)

SELECT
    SENDER."UserName"   AS "SENDER_USERNAME",
    RECEIVER."UserName" AS "RECEIVER_USERNAME",
    "VOTES_FROM_S_TO_R" AS "UPVOTES_SENDER_TO_RECEIVER",
    "VOTES_FROM_R_TO_S" AS "UPVOTES_RECEIVER_TO_SENDER"
FROM PAIR_COUNTS PC
JOIN META_KAGGLE.META_KAGGLE.USERS SENDER
     ON PC."SENDER_ID"   = SENDER."Id"
JOIN META_KAGGLE.META_KAGGLE.USERS RECEIVER
     ON PC."RECEIVER_ID" = RECEIVER."Id"
ORDER BY
    "VOTES_FROM_S_TO_R" DESC NULLS LAST,
    "VOTES_FROM_R_TO_S" DESC NULLS LAST
LIMIT 1;