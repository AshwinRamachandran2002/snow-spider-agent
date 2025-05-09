WITH first_messages AS (
    /* first message in each forum topic (where Kaggle stores the id explicitly) */
    SELECT m."Id",
           m."PostUserId"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
    WHERE m."Id" IN (
        SELECT t."FirstForumMessageId"
        FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS t
        WHERE t."FirstForumMessageId" IS NOT NULL
    )
),
message_scores AS (
    /* score = number of distinct users who voted on that message */
    SELECT fm."Id"                           AS "MessageId",
           fm."PostUserId",
           COUNT(DISTINCT v."FromUserId")    AS "MessageScore"
    FROM first_messages  fm
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v
           ON v."ForumMessageId" = fm."Id"
    GROUP BY fm."Id", fm."PostUserId"
),
avg_score AS (
    /* average score across all first messages */
    SELECT AVG("MessageScore") AS "AvgScore"
    FROM message_scores
),
user_best_scores AS (
    /* each user’s highest-scoring first message */
    SELECT ms."PostUserId",
           MAX(ms."MessageScore") AS "BestScore"
    FROM message_scores ms
    GROUP BY ms."PostUserId"
),
ranked_users AS (
    /* attach usernames and rank by best score */
    SELECT u."UserName",
           ub."BestScore"
    FROM user_best_scores ub
    JOIN META_KAGGLE.META_KAGGLE.USERS u
      ON u."Id" = ub."PostUserId"
    ORDER BY ub."BestScore" DESC NULLS LAST
    LIMIT 3         -- top three users
)
SELECT ru."UserName",
       ABS(ru."BestScore" - a."AvgScore") AS "ScoreDifference"
FROM ranked_users ru
CROSS JOIN avg_score a;