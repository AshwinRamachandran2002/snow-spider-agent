WITH first_messages AS (      -- all messages that start a forum topic
    SELECT 
        m."Id"           AS "message_id",
        m."PostUserId"   AS "author_user_id"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES  m
    JOIN META_KAGGLE.META_KAGGLE.FORUMTOPICS    t
          ON t."FirstForumMessageId" = m."Id"
), msg_scores AS (            -- message-level score = distinct voters
    SELECT
        fm."message_id",
        fm."author_user_id",
        COUNT(DISTINCT v."FromUserId") AS "message_score"
    FROM first_messages fm
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v
           ON v."ForumMessageId" = fm."message_id"
    GROUP BY fm."message_id", fm."author_user_id"
), avg_val AS (               -- overall average score
    SELECT AVG("message_score") AS "avg_score"
    FROM msg_scores
), per_user AS (              -- best (highest-scoring) first-message per user
    SELECT
        "author_user_id",
        MAX("message_score") AS "user_message_score"
    FROM msg_scores
    GROUP BY "author_user_id"
)
SELECT
    u."UserName"                                            AS "username",
    ABS(p."user_message_score" - a."avg_score")             AS "score_diff_from_avg"
FROM per_user                 p
CROSS JOIN avg_val            a
JOIN META_KAGGLE.META_KAGGLE.USERS u
  ON u."Id" = p."author_user_id"
ORDER BY p."user_message_score" DESC NULLS LAST
LIMIT 3;