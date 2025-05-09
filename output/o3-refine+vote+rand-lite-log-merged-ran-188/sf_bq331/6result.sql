WITH first_messages AS (          -- all “first” messages of every forum topic
    SELECT
        fm."Id"        AS message_id ,
        fm."PostUserId" AS user_id
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS"  ft
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
          ON fm."Id" = CAST(ft."FirstForumMessageId" AS NUMBER)
    WHERE ft."FirstForumMessageId" IS NOT NULL
),
message_scores AS (               -- score = # distinct users who voted
    SELECT
        fm.message_id ,
        fm.user_id ,
        COUNT(DISTINCT vm."FromUserId") AS message_score
    FROM first_messages  fm
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" vm
           ON vm."ForumMessageId" = fm.message_id
    GROUP BY fm.message_id , fm.user_id
),
avg_score AS (                     -- average score of **all** first messages
    SELECT AVG(message_score) AS avg_message_score
    FROM   message_scores
),
user_best AS (                     -- each user’s best‑scored first message
    SELECT
        user_id ,
        MAX(message_score) AS best_score
    FROM message_scores
    GROUP BY user_id
),
ranked_users AS (                  -- rank users by that best score
    SELECT
        user_id ,
        best_score ,
        ROW_NUMBER() OVER (ORDER BY best_score DESC NULLS LAST, user_id) AS rn
    FROM user_best
)
SELECT
    u."UserName" ,
    ABS(ru.best_score - a.avg_message_score) AS score_difference
FROM ranked_users ru
JOIN META_KAGGLE.META_KAGGLE."USERS" u
     ON u."Id" = ru.user_id
CROSS JOIN avg_score a
WHERE ru.rn <= 3                   -- top three users
ORDER BY ru.best_score DESC NULLS LAST, ru.user_id;