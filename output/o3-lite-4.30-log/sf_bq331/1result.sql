WITH per_message AS (
    SELECT
        fm."PostUserId"                              AS "author_id",
        COUNT(DISTINCT fmv."FromUserId")             AS "msg_score"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS          ft
    JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES        fm
          ON fm."Id" = ft."FirstForumMessageId"
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES fmv
          ON fmv."ForumMessageId" = fm."Id"
    WHERE ft."FirstForumMessageId" IS NOT NULL
    GROUP BY fm."PostUserId", fm."Id"
),
avg_score AS (
    SELECT AVG("msg_score") AS "avg_msg_score"
    FROM per_message
),
user_best AS (
    SELECT
        "author_id",
        MAX("msg_score") AS "best_msg_score"
    FROM per_message
    GROUP BY "author_id"
)
SELECT
    u."UserName"                                                    AS "username",
    ROUND(ABS(ub."best_msg_score" - a."avg_msg_score"), 4)          AS "absolute_score_difference"
FROM user_best                       ub
JOIN META_KAGGLE.META_KAGGLE.USERS   u  ON u."Id" = ub."author_id"
CROSS JOIN avg_score                 a
ORDER BY ub."best_msg_score" DESC NULLS LAST, u."UserName"
LIMIT 3;