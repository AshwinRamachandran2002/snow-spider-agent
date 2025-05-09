WITH first_message_scores AS (
    /* score for every first message in forum topics */
    SELECT 
        m."Id"          AS "MessageId",
        m."PostUserId",
        COUNT(DISTINCT v."FromUserId") AS "MessageScore"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS  t
    JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
        ON m."Id" = t."FirstForumMessageId"
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v
        ON v."ForumMessageId" = m."Id"
    GROUP BY m."Id", m."PostUserId"
), avg_score AS (
    /* overall average message score */
    SELECT AVG("MessageScore") AS "AvgScore"
    FROM first_message_scores
), user_best AS (
    /* each user’s highest-scoring first message */
    SELECT 
        "PostUserId",
        MAX("MessageScore") AS "TopMessageScore"
    FROM first_message_scores
    GROUP BY "PostUserId"
)
SELECT
    u."UserName",
    ABS(ub."TopMessageScore" - a."AvgScore") AS "ScoreDifference"
FROM user_best                      ub
JOIN META_KAGGLE.META_KAGGLE.USERS  u  ON u."Id" = ub."PostUserId"
CROSS JOIN avg_score                a
ORDER BY ub."TopMessageScore" DESC NULLS LAST
LIMIT 3;