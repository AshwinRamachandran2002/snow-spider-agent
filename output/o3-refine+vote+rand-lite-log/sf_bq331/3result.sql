WITH first_messages AS (               -- first message for every forum topic
    SELECT "FirstForumMessageId" AS "MessageId"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS
    WHERE "FirstForumMessageId" IS NOT NULL
),
message_scores AS (                    -- score of each first message
    SELECT
        fm."Id"                                      AS "MessageId",
        fm."PostUserId"                              AS "UserId",
        COALESCE(COUNT(DISTINCT fmv."FromUserId"),0) AS "Score"
    FROM first_messages f
    JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES fm
      ON fm."Id" = f."MessageId"
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES fmv
      ON fmv."ForumMessageId" = fm."Id"
    GROUP BY fm."Id", fm."PostUserId"
),
avg_score AS (                         -- average score of all first messages
    SELECT AVG("Score") AS "AvgScore"
    FROM message_scores
),
user_best AS (                         -- best (highest‑scoring) first message per user
    SELECT
        "UserId",
        MAX("Score") AS "BestScore"
    FROM message_scores
    GROUP BY "UserId"
),
ranked_users AS (                      -- rank users by their best score
    SELECT
        ub.*,
        ROW_NUMBER() OVER (ORDER BY ub."BestScore" DESC, ub."UserId") AS rn
    FROM user_best ub
)
SELECT
    u."UserName"                                   AS "USERNAME",
    ABS(r."BestScore" - a."AvgScore")              AS "SCORE_DIFFERENCE"
FROM ranked_users r
JOIN META_KAGGLE.META_KAGGLE.USERS u
  ON u."Id" = r."UserId"
CROSS JOIN avg_score a
WHERE r.rn <= 3
ORDER BY r."BestScore" DESC NULLS LAST, u."UserName";