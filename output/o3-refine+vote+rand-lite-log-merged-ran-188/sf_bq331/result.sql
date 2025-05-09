WITH first_messages AS (      /* all “first” messages that open each topic */
    SELECT
        fm."Id"          AS message_id,
        fm."PostUserId"  AS user_id
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" ft
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
          ON fm."Id" = ft."FirstForumMessageId"
    WHERE ft."FirstForumMessageId" IS NOT NULL
),
message_scores AS (           /* score = # distinct voters on that message */
    SELECT
        f.message_id,
        f.user_id,
        COUNT(DISTINCT v."FromUserId") AS message_score
    FROM first_messages f
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
           ON v."ForumMessageId" = f.message_id
    GROUP BY f.message_id, f.user_id
),
avg_score AS (                 /* average score across ALL first messages */
    SELECT AVG(message_score) AS avg_message_score
    FROM message_scores
),
user_best AS (                 /* each user’s best‑scoring first message */
    SELECT
        user_id,
        MAX(message_score) AS best_score
    FROM message_scores
    GROUP BY user_id
),
ranked AS (                    /* rank users by their best message score */
    SELECT
        ub.user_id,
        ub.best_score,
        ABS(ub.best_score - a.avg_message_score) AS diff_from_avg,
        ROW_NUMBER() OVER (ORDER BY ub.best_score DESC, ub.user_id) AS rn
    FROM user_best ub
    CROSS JOIN avg_score a
)
SELECT
    u."UserName",
    ROUND(r.diff_from_avg, 4) AS "ScoreDifference"
FROM ranked r
JOIN META_KAGGLE.META_KAGGLE."USERS" u
  ON u."Id" = r.user_id
WHERE r.rn <= 3
ORDER BY r.best_score DESC NULLS LAST, r.user_id;