/* Top 3 users (unique) who wrote the first message in forum topics,
   ranked by the highest score of any of their first–topic messages.
   “Message score” = # distinct voters on that message.
   The output shows each user’s name and the absolute difference
   between that (best) score and the average score of ALL first‑topic
   messages. */

WITH first_messages AS (          -- every first message id
    SELECT DISTINCT "FirstForumMessageId" AS "MessageId"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS
    WHERE "FirstForumMessageId" IS NOT NULL
),
message_votes AS (                -- score per message
    SELECT "ForumMessageId"   AS "MessageId",
           COUNT(DISTINCT "FromUserId") AS "MessageScore"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "ForumMessageId"
),
scores AS (                       -- score for each first message
    SELECT fm."PostUserId"        AS "UserId",
           COALESCE(mv."MessageScore", 0) AS "MessageScore"
    FROM first_messages f
    JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES fm
          ON fm."Id" = f."MessageId"
    LEFT JOIN message_votes mv
          ON mv."MessageId" = f."MessageId"
),
avg_msg_score AS (                -- average across ALL first messages
    SELECT AVG("MessageScore") AS "AvgScore"
    FROM scores
),
user_best_scores AS (             -- best first‑message score per user
    SELECT "UserId",
           MAX("MessageScore") AS "BestScore"
    FROM scores
    GROUP BY "UserId"
),
ranked AS (
    SELECT  u."UserName",
            ub."BestScore",
            ABS(ub."BestScore" - a."AvgScore") AS "ScoreDiff"
    FROM user_best_scores  ub
    CROSS JOIN avg_msg_score a
    JOIN META_KAGGLE.META_KAGGLE.USERS u
         ON u."Id" = ub."UserId"
)
SELECT "UserName",
       "ScoreDiff"
FROM ranked
ORDER BY "BestScore" DESC NULLS LAST, "UserName"
LIMIT 3;