WITH first_messages AS (         -- every topic’s first post
    SELECT DISTINCT "FirstForumMessageId" AS "MessageId"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS"
    WHERE "FirstForumMessageId" IS NOT NULL
),
message_scores AS (              -- count distinct voters for each first post
    SELECT
        fm."MessageId",
        COUNT(DISTINCT fmv."FromUserId") AS "MessageScore"
    FROM first_messages   fm
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
           ON fm."MessageId" = fmv."ForumMessageId"
    GROUP BY fm."MessageId"
),
scores_with_users AS (           -- attach post author
    SELECT
        ms."MessageId",
        ms."MessageScore",
        m."PostUserId" AS "AuthorUserId"
    FROM message_scores ms
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" m
          ON m."Id" = ms."MessageId"
),
avg_score AS (                    -- overall average score
    SELECT AVG("MessageScore") AS "AvgScore"
    FROM   scores_with_users
)
SELECT
    u."UserName",
    s."MessageScore",
    ABS(s."MessageScore" - a."AvgScore") AS "ScoreDifferenceFromAverage"
FROM scores_with_users s
JOIN META_KAGGLE.META_KAGGLE."USERS" u
      ON u."Id" = s."AuthorUserId"
CROSS JOIN avg_score a
ORDER BY s."MessageScore" DESC NULLS LAST
LIMIT 3;