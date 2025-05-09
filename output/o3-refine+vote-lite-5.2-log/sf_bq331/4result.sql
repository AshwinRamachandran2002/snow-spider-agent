WITH first_messages AS (      -- every topic’s first post + its vote‑count
    SELECT
        m."Id"                        AS message_id,
        m."PostUserId"                AS user_id,
        COALESCE(COUNT(DISTINCT v."FromUserId"),0) AS message_score
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" t
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" m
          ON t."FirstForumMessageId" = m."Id"
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
          ON v."ForumMessageId" = m."Id"
    GROUP BY m."Id", m."PostUserId"
),

avg_score AS (                -- average score of all first messages
    SELECT AVG(message_score) AS avg_score
    FROM   first_messages
),

user_best AS (                -- each user’s highest‑scoring first message
    SELECT
        user_id,
        MAX(message_score) AS message_score
    FROM first_messages
    GROUP BY user_id
),

ranked AS (                   -- add usernames & difference from average
    SELECT
        u."UserName"                                   AS username,
        ABS(b.message_score - a.avg_score)             AS diff_from_avg,
        b.message_score
    FROM user_best b
    JOIN META_KAGGLE.META_KAGGLE."USERS" u
         ON u."Id" = b.user_id
    CROSS JOIN avg_score a
    ORDER BY b.message_score DESC NULLS LAST, u."UserName"
    LIMIT 3
)

SELECT
    username,
    diff_from_avg
FROM ranked;