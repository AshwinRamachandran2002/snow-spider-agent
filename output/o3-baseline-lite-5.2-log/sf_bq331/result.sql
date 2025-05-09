WITH first_messages AS (     -- every first post that opened a forum topic
    SELECT ft."FirstForumMessageId"::NUMBER AS "MessageId"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" ft
    WHERE ft."FirstForumMessageId" IS NOT NULL
),

message_scores AS (          -- score = distinct voters on that message
    SELECT
        fm."MessageId",
        msg."PostUserId"          AS "AuthorId",
        COUNT(DISTINCT vm."FromUserId") AS "MessageScore"
    FROM first_messages fm
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" msg
          ON msg."Id" = fm."MessageId"
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" vm
          ON vm."ForumMessageId" = fm."MessageId"
    GROUP BY fm."MessageId", msg."PostUserId"
),

avg_score AS (               -- average score across ALL first messages
    SELECT AVG("MessageScore") AS "AvgMessageScore"
    FROM message_scores
),

user_scores AS (             -- each user’s best‑scoring first message
    SELECT
        "AuthorId",
        MAX("MessageScore") AS "UserScore"
    FROM message_scores
    GROUP BY "AuthorId"
),

ranked_users AS (            -- rank users by that best score
    SELECT
        us."AuthorId",
        us."UserScore",
        ABS(us."UserScore" - a."AvgMessageScore") AS "ScoreDiff",
        ROW_NUMBER() OVER (ORDER BY us."UserScore" DESC, us."AuthorId") AS rn
    FROM user_scores us
    CROSS JOIN avg_score a
)

SELECT
    u."UserName",
    ROUND(r."ScoreDiff", 4) AS "ScoreDiff"
FROM ranked_users r
JOIN META_KAGGLE.META_KAGGLE."USERS" u
      ON u."Id" = r."AuthorId"
WHERE r.rn <= 3
ORDER BY r.rn;