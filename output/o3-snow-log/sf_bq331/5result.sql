WITH first_messages AS (
    SELECT 
        ft."FirstForumMessageId"            AS "MessageId"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS ft
    WHERE ft."FirstForumMessageId" IS NOT NULL
),  

message_scores AS (
    SELECT
        fm."Id"                             AS "MessageId",
        fm."PostUserId"                     AS "AuthorUserId",
        COALESCE(COUNT(DISTINCT fmv."FromUserId"),0)  AS "MessageScore"
    FROM first_messages fml
    JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES fm
         ON fm."Id" = fml."MessageId"
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES fmv
         ON fmv."ForumMessageId" = fm."Id"
    GROUP BY
        fm."Id",
        fm."PostUserId"
),  

avg_score AS (
    SELECT 
        AVG("MessageScore") AS "AvgScore"
    FROM message_scores
),  

user_best AS (
    SELECT
        "AuthorUserId",
        MAX("MessageScore") AS "BestMessageScore"
    FROM message_scores
    GROUP BY "AuthorUserId"
),  

ranked_users AS (
    SELECT
        u."UserName",
        ub."BestMessageScore",
        ABS(ub."BestMessageScore" - a."AvgScore") AS "ScoreDifference"
    FROM user_best          ub
    JOIN META_KAGGLE.META_KAGGLE.USERS u
         ON u."Id" = ub."AuthorUserId"
    CROSS JOIN avg_score    a
)

SELECT 
    "UserName",
    "ScoreDifference"
FROM ranked_users
ORDER BY "BestMessageScore" DESC NULLS LAST
LIMIT 3;