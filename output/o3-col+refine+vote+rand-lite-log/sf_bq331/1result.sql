WITH first_messages AS (          -- all very first posts in every forum topic
    SELECT
        ft."FirstForumMessageId" AS "MessageId",
        fm."PostUserId"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS"  ft
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
      ON fm."Id" = ft."FirstForumMessageId"
),

message_scores AS (               -- score = # distinct voters on that first post
    SELECT
        fm."MessageId",
        fm."PostUserId",
        COUNT(DISTINCT fmv."FromUserId") AS "MessageScore"
    FROM first_messages fm
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
           ON fmv."ForumMessageId" = fm."MessageId"
    GROUP BY fm."MessageId", fm."PostUserId"
),

avg_score AS (                    -- average score across all first messages
    SELECT AVG("MessageScore") AS "AvgScore"
    FROM message_scores
),

user_best AS (                    -- each user’s single highest-scoring first post
    SELECT
        "PostUserId",
        MAX("MessageScore") AS "TopMessageScore"
    FROM message_scores
    GROUP BY "PostUserId"
),

ranked_users AS (                 -- rank users by that best score
    SELECT
        ub."PostUserId",
        ub."TopMessageScore",
        ABS(ub."TopMessageScore" - a."AvgScore") AS "ScoreDiff",
        ROW_NUMBER() OVER (ORDER BY ub."TopMessageScore" DESC NULLS LAST) AS rn
    FROM user_best ub
    CROSS JOIN avg_score a
)

SELECT
    u."UserName",
    ROUND(r."ScoreDiff", 4) AS "ScoreDifferenceFromAverage"
FROM ranked_users r
JOIN META_KAGGLE.META_KAGGLE."USERS" u
  ON u."Id" = r."PostUserId"
WHERE r.rn <= 3                   -- top-3 users
ORDER BY r."TopMessageScore" DESC NULLS LAST;