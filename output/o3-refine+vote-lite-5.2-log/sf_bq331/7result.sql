WITH "first_messages" AS (   -- all first messages of every forum topic
    SELECT
        ft."FirstForumMessageId" AS "MessageId",
        fm."PostUserId"          AS "UserId"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS"  ft
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
      ON fm."Id" = ft."FirstForumMessageId"
    WHERE ft."FirstForumMessageId" IS NOT NULL
),

"message_scores" AS (        -- score of each first message = # distinct voters
    SELECT
        fm."MessageId",
        fm."UserId",
        COUNT(DISTINCT fmv."FromUserId") AS "Score"
    FROM "first_messages" fm
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
      ON fmv."ForumMessageId" = fm."MessageId"
    GROUP BY fm."MessageId", fm."UserId"
),

"avg_score" AS (             -- average score of all first messages
    SELECT AVG("Score") AS "AvgScore"
    FROM "message_scores"
),

"user_scores" AS (           -- best score attained by each user
    SELECT
        "UserId",
        MAX("Score") AS "UserScore"
    FROM "message_scores"
    GROUP BY "UserId"
)

SELECT
    u."UserName",
    ABS(us."UserScore" - a."AvgScore") AS "ScoreDifference"
FROM "user_scores"            us
JOIN META_KAGGLE.META_KAGGLE."USERS" u
  ON u."Id" = us."UserId"
CROSS JOIN "avg_score"        a
ORDER BY us."UserScore" DESC NULLS LAST, us."UserId"
LIMIT 3;