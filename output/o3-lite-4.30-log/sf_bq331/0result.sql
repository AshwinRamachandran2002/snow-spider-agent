WITH first_msg_scores AS (   -- score for every first message
    SELECT
        fm."Id"                      AS "MsgId",
        fm."PostUserId",
        COUNT(DISTINCT fmv."FromUserId") AS "MsgScore"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMTOPICS"  ft
    JOIN "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGES" fm
         ON fm."Id" = ft."FirstForumMessageId"
    LEFT JOIN "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES" fmv
         ON fmv."ForumMessageId" = fm."Id"
    GROUP BY fm."Id", fm."PostUserId"
),
avg_score AS (               -- average score of all first messages
    SELECT AVG("MsgScore") AS "AvgScore"
    FROM first_msg_scores
),
user_best AS (               -- best (highest‑scoring) first message per user
    SELECT
        "PostUserId" AS "UserId",
        MAX("MsgScore") AS "BestScore"
    FROM first_msg_scores
    GROUP BY "PostUserId"
),
top_users AS (               -- top‑3 users by their best score
    SELECT *
    FROM user_best
    ORDER BY "BestScore" DESC NULLS LAST, "UserId" ASC
    LIMIT 3
)
SELECT
    u."UserName"                                           AS "username",
    ROUND(ABS(t."BestScore" - a."AvgScore"), 4)            AS "absolute_score_difference"
FROM top_users t
CROSS JOIN avg_score a
JOIN "META_KAGGLE"."META_KAGGLE"."USERS" u
     ON u."Id" = t."UserId"
ORDER BY t."BestScore" DESC NULLS LAST, u."Id" ASC;