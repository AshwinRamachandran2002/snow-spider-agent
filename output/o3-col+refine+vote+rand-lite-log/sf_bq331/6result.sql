-- Top-3 authors of first-forum messages by distinct voter count
WITH first_message_scores AS (
    /* score for every message that starts a forum topic */
    SELECT
        v."ForumMessageId"                  AS "first_msg_id",
        COUNT(DISTINCT v."FromUserId")      AS "message_score"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"  v
    JOIN META_KAGGLE.META_KAGGLE."FORUMTOPICS"        t
          ON t."FirstForumMessageId" = v."ForumMessageId"
    GROUP BY v."ForumMessageId"
),
avg_score AS (
    /* global average across all first-messages (that received at least one vote) */
    SELECT AVG("message_score") AS "avg_first_msg_score"
    FROM   first_message_scores
),
user_best_scores AS (
    /* each author's highest-scoring first message */
    SELECT
        fm."PostUserId"             AS "author_user_id",
        MAX(fms."message_score")    AS "author_msg_score"
    FROM first_message_scores                        fms
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
          ON fm."Id" = fms."first_msg_id"
    GROUP BY fm."PostUserId"
)

SELECT
    u."UserName",
    ub."author_msg_score"                               AS "message_score",
    ABS(ub."author_msg_score" - a."avg_first_msg_score") AS "abs_diff_from_avg"
FROM user_best_scores                       ub
JOIN META_KAGGLE.META_KAGGLE."USERS"        u  ON u."Id" = ub."author_user_id"
CROSS JOIN avg_score                        a
ORDER BY ub."author_msg_score" DESC NULLS LAST
LIMIT 3;