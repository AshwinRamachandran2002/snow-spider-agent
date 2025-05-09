WITH first_messages AS (               -- ids of the very first messages in every forum topic
    SELECT "FirstForumMessageId" AS message_id
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS"
    WHERE "FirstForumMessageId" IS NOT NULL
),

message_scores AS (                    -- score = # distinct voters on that first message
    SELECT
        fm."Id"                       AS message_id,
        fm."PostUserId"               AS author_id,
        COUNT(DISTINCT fmv."FromUserId") AS message_score
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"      fm
    JOIN first_messages                                fmsg
         ON fmsg.message_id = fm."Id"
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
           ON fmv."ForumMessageId" = fm."Id"
    GROUP BY fm."Id", fm."PostUserId"
),

avg_score_cte AS (                     -- average score over ALL first-messages
    SELECT AVG(message_score) AS avg_score
    FROM message_scores
),

user_best_scores AS (                  -- each user keeps only his/her highest-scored first message
    SELECT
        author_id,
        message_id,
        message_score,
        ROW_NUMBER() OVER (PARTITION BY author_id
                           ORDER BY message_score DESC) AS rn
    FROM message_scores
),

top_users AS (                         -- top 3 users by that best message score
    SELECT
        author_id,
        message_score
    FROM user_best_scores
    WHERE rn = 1
    QUALIFY ROW_NUMBER() OVER (ORDER BY message_score DESC NULLS LAST) <= 3
)

SELECT
    u."UserName"                                              AS "username",
    ABS(tu.message_score - a.avg_score)                       AS "score_difference"
FROM top_users                     tu
JOIN META_KAGGLE.META_KAGGLE."USERS" u
      ON u."Id" = tu.author_id
CROSS JOIN avg_score_cte           a
ORDER BY tu.message_score DESC NULLS LAST;