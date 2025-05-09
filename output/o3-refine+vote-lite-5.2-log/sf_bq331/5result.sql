WITH first_messages AS (           -- earliest message in each topic
    SELECT
        fm."ForumTopicId",
        fm."Id"                                    AS "MessageId",
        fm."PostUserId",
        ROW_NUMBER() OVER (
            PARTITION BY fm."ForumTopicId"
            ORDER BY TO_TIMESTAMP_NTZ(fm."PostDate",'MM/DD/YYYY HH24:MI:SS')
        )                                          AS rn
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
),
topic_first AS (                   -- keep only the very first message per topic
    SELECT "ForumTopicId","MessageId","PostUserId"
    FROM   first_messages
    WHERE  rn = 1
),
message_scores AS (                -- number of distinct voters for each first message
    SELECT
        tf."MessageId",
        tf."PostUserId",
        COALESCE(COUNT(DISTINCT fmv."FromUserId"),0) AS "MessageScore"
    FROM   topic_first tf
    LEFT  JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
           ON fmv."ForumMessageId" = tf."MessageId"
    GROUP BY tf."MessageId", tf."PostUserId"
),
avg_score AS (                     -- average score of all first messages
    SELECT AVG("MessageScore") AS "AvgScore"
    FROM   message_scores
),
user_best AS (                     -- best‑scoring first message for each user
    SELECT
        ms."PostUserId",
        ms."MessageScore",
        ROW_NUMBER() OVER (
            PARTITION BY ms."PostUserId"
            ORDER BY ms."MessageScore" DESC, ms."MessageId"
        ) AS rn
    FROM   message_scores ms
),
user_top AS (                      -- one record per user (their best message)
    SELECT "PostUserId","MessageScore"
    FROM   user_best
    WHERE  rn = 1
)
SELECT
    u."UserName",
    ROUND(ABS(ut."MessageScore" - a."AvgScore"),4) AS "ScoreDifference"
FROM   user_top ut
JOIN   META_KAGGLE.META_KAGGLE."USERS" u
       ON u."Id" = ut."PostUserId"
CROSS  JOIN avg_score a
ORDER  BY ut."MessageScore" DESC NULLS LAST, ut."PostUserId"
LIMIT  3;