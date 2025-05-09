/* 1. Identify every “first message” for each forum topic            */
/* 2. Compute its message score = #distinct voters on that message   */
/* 3. Calculate the global average of these scores                   */
/* 4. For every author keep only the highest-scoring first message   */
/* 5. Pick the three authors with the largest such scores            */
/* 6. Return their username and |score – average score|              */
WITH first_messages AS (
    SELECT
        FT."FirstForumMessageId"      AS "message_id"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" FT
    WHERE FT."FirstForumMessageId" IS NOT NULL
),
message_scores AS (
    SELECT
        FM."Id"                       AS "message_id",
        FM."PostUserId"               AS "user_id",
        COUNT(DISTINCT FMV."FromUserId")::FLOAT AS "message_score"
    FROM first_messages M
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" FM
          ON FM."Id" = M."message_id"
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" FMV
          ON FMV."ForumMessageId" = FM."Id"
    GROUP BY FM."Id", FM."PostUserId"
),
avg_score_cte AS (
    SELECT AVG("message_score") AS "avg_score"
    FROM   message_scores
),
user_best AS (
    SELECT
        "user_id",
        MAX("message_score") AS "best_score"
    FROM message_scores
    GROUP BY "user_id"
),
ranked_users AS (
    SELECT
        UB."user_id",
        UB."best_score",
        A."avg_score",
        ABS(UB."best_score" - A."avg_score") AS "score_diff",
        ROW_NUMBER() OVER (ORDER BY UB."best_score" DESC NULLS LAST) AS "rn"
    FROM user_best UB
    CROSS JOIN avg_score_cte A
)
SELECT
    U."UserName"                           AS "username",
    ROUND(RU."score_diff", 4)              AS "score_difference"
FROM ranked_users RU
JOIN META_KAGGLE.META_KAGGLE."USERS" U
     ON U."Id" = RU."user_id"
WHERE RU."rn" <= 3
ORDER BY RU."best_score" DESC NULLS LAST;