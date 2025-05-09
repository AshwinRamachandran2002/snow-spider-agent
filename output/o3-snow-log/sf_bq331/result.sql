WITH first_messages AS (        -- all first messages in every forum topic
    SELECT
        FT."FirstForumMessageId"::NUMBER       AS "MessageId",
        FM."PostUserId"                        AS "UserId"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" FT
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" FM
          ON FM."Id" = FT."FirstForumMessageId"
    WHERE FT."FirstForumMessageId" IS NOT NULL
),
message_scores AS (             -- score of each first message = # distinct voters
    SELECT
        FM."MessageId",
        FM."UserId",
        COALESCE(COUNT(DISTINCT FMV."FromUserId"),0) AS "MessageScore"
    FROM first_messages FM
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" FMV
           ON FMV."ForumMessageId" = FM."MessageId"
    GROUP BY FM."MessageId", FM."UserId"
),
average_score AS (              -- average score across all first messages
    SELECT AVG("MessageScore") AS "AvgScore"
    FROM message_scores
),
user_best_score AS (            -- best (highest-scoring) first message per user
    SELECT
        "UserId",
        MAX("MessageScore") AS "BestMessageScore"
    FROM message_scores
    GROUP BY "UserId"
),
user_with_diff AS (             -- difference from average for each user
    SELECT
        UBS."UserId",
        U."UserName",
        UBS."BestMessageScore",
        ABS(UBS."BestMessageScore" - AVG_S."AvgScore") AS "ScoreDiff"
    FROM user_best_score UBS
    JOIN META_KAGGLE.META_KAGGLE."USERS" U
          ON U."Id" = UBS."UserId"
    CROSS JOIN average_score AVG_S
)
SELECT
    "UserName",
    ROUND("ScoreDiff",4) AS "ScoreDifferenceFromAvg"
FROM user_with_diff
ORDER BY "BestMessageScore" DESC NULLS LAST
LIMIT 3;