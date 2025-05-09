WITH FirstMsgScores AS (          -- score of every “first” forum message
    SELECT
        CAST(t."FirstForumMessageId" AS NUMBER)       AS "MessageId",
        m."PostUserId",
        COUNT(DISTINCT v."FromUserId")                AS "MessageScore"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS         t
    JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES       m
          ON m."Id" = CAST(t."FirstForumMessageId" AS NUMBER)
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v
          ON v."ForumMessageId" = m."Id"
    WHERE t."FirstForumMessageId" IS NOT NULL
    GROUP BY CAST(t."FirstForumMessageId" AS NUMBER),
             m."PostUserId"
),
UserBestScores AS (               -- best (highest-scoring) first-message per user
    SELECT
        "PostUserId",
        MAX("MessageScore") AS "BestScore"
    FROM FirstMsgScores
    GROUP BY "PostUserId"
),
AvgScore AS (                     -- average score across all first messages
    SELECT AVG("MessageScore") AS "AvgFirstMsgScore"
    FROM   FirstMsgScores
)
SELECT
    u."UserName",
    ROUND(ABS(ubs."BestScore" - a."AvgFirstMsgScore"), 4) AS "AbsDiffToAvg"
FROM   UserBestScores                             ubs
CROSS  JOIN AvgScore                              a
JOIN   META_KAGGLE.META_KAGGLE.USERS              u
       ON u."Id" = ubs."PostUserId"
ORDER  BY ubs."BestScore" DESC NULLS LAST
LIMIT 3;