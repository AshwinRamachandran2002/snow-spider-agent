WITH "PAIR_COUNTS" AS (        -- total votes each user gave another user
    SELECT
        "FromUserId" AS "GiverId",
        "ToUserId"   AS "ReceiverId",
        COUNT(*)     AS "VotesGiven"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId", "ToUserId"
),
"PAIR_WITH_RETURN" AS (        -- add how many votes were returned in the opposite direction
    SELECT
        pc."GiverId",
        pc."ReceiverId",
        pc."VotesGiven",
        COALESCE(rc."VotesGiven", 0) AS "VotesReturned"
    FROM "PAIR_COUNTS" pc
    LEFT JOIN "PAIR_COUNTS" rc
           ON rc."GiverId"    = pc."ReceiverId"
          AND rc."ReceiverId" = pc."GiverId"
),
"TOP_PAIR" AS (                -- keep only the pair with the most received votes, break ties by returned votes
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY "VotesGiven" DESC, "VotesReturned" DESC) AS "row_num"
    FROM "PAIR_WITH_RETURN"
)
SELECT
    COALESCE(g."UserName", CAST(tp."GiverId"    AS VARCHAR)) AS "GiverUserName",
    COALESCE(r."UserName", CAST(tp."ReceiverId" AS VARCHAR)) AS "ReceiverUserName",
    tp."VotesGiven"    AS "Upvotes_Given",
    tp."VotesReturned" AS "Upvotes_Returned"
FROM "TOP_PAIR" tp
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS g
       ON g."Id" = tp."GiverId"
LEFT JOIN META_KAGGLE.META_KAGGLE.USERS r
       ON r."Id" = tp."ReceiverId"
WHERE tp."row_num" = 1;