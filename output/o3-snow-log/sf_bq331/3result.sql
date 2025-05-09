WITH first_messages AS (
    SELECT 
        ft."FirstForumMessageId"::NUMBER AS "MessageId"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" ft
    WHERE ft."FirstForumMessageId" IS NOT NULL
),
message_scores AS (
    SELECT
        fm."Id"                        AS "MessageId",
        fm."PostUserId"                AS "AuthorId",
        COALESCE(COUNT(DISTINCT fmv."FromUserId"),0) AS "MessageScore"
    FROM first_messages m
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
          ON fm."Id" = m."MessageId"
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
          ON fmv."ForumMessageId" = m."MessageId"
    GROUP BY fm."Id", fm."PostUserId"
),
avg_score AS (
    SELECT AVG("MessageScore") AS "AvgScore"
    FROM message_scores
),
user_best AS (
    SELECT
        "AuthorId",
        MAX("MessageScore") AS "BestScore"
    FROM message_scores
    GROUP BY "AuthorId"
)
SELECT
    u."UserName",
    ABS(ub."BestScore" - a."AvgScore") AS "ScoreDifference"
FROM user_best ub
JOIN META_KAGGLE.META_KAGGLE."USERS" u
      ON u."Id" = ub."AuthorId"
CROSS JOIN avg_score a
ORDER BY ub."BestScore" DESC NULLS LAST
LIMIT 3;