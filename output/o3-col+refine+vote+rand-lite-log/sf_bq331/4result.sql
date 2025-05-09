/* Top three users by score of the first message they posted in forum topics */
WITH first_message_scores AS (        -- score for every first-message
    SELECT
        t."FirstForumMessageId"                          AS "MessageId",
        COUNT(DISTINCT v."FromUserId")                   AS "MessageScore"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS"      t
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
           ON v."ForumMessageId" = t."FirstForumMessageId"
    GROUP BY t."FirstForumMessageId"
),
avg_score AS (                       -- average score of all first-messages
    SELECT AVG("MessageScore") AS "AvgScore"
    FROM   first_message_scores
),
author_scores AS (                   -- accumulate scores per author
    SELECT
        fm."PostUserId"                             AS "AuthorUserId",
        COUNT(DISTINCT v."FromUserId")              AS "MessageScore"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS"  t
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
          ON fm."Id" = t."FirstForumMessageId"
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
           ON v."ForumMessageId" = fm."Id"
    GROUP BY fm."PostUserId"
)
SELECT
    u."UserName",
    ABS(a."MessageScore" - s."AvgScore")          AS "AbsDiffFromAvg",
    a."MessageScore"
FROM       author_scores a
CROSS JOIN avg_score      s
JOIN       META_KAGGLE.META_KAGGLE."USERS" u
       ON u."Id" = a."AuthorUserId"
ORDER BY a."MessageScore" DESC NULLS LAST
LIMIT 3;