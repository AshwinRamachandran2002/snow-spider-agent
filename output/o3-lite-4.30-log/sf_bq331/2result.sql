WITH first_message_scores AS (
    SELECT
        v."ForumMessageId",
        COUNT(DISTINCT v."FromUserId") AS "MessageScore"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES" v
    JOIN "META_KAGGLE"."META_KAGGLE"."FORUMTOPICS" t
      ON t."FirstForumMessageId" = v."ForumMessageId"
    GROUP BY v."ForumMessageId"
),
avg_score AS (
    SELECT AVG("MessageScore") AS "AvgScore"
    FROM first_message_scores
),
user_best_scores AS (
    SELECT
        m."PostUserId",
        MAX(f."MessageScore") AS "BestMessageScore"
    FROM first_message_scores f
    JOIN "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGES" m
      ON m."Id" = f."ForumMessageId"
    GROUP BY m."PostUserId"
)
SELECT
    u."UserName"                                                        AS username,
    ROUND(ABS(ubs."BestMessageScore" - a."AvgScore"), 4)                AS absolute_score_difference
FROM user_best_scores ubs
JOIN "META_KAGGLE"."META_KAGGLE"."USERS" u
  ON u."Id" = ubs."PostUserId"
CROSS JOIN avg_score a
ORDER BY ubs."BestMessageScore" DESC NULLS LAST, u."UserName"
LIMIT 3;