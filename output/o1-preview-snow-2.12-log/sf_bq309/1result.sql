WITH answer_ratios AS (
    SELECT
        a."parent_id" AS "question_id",
        MAX(ROUND(a."score"::FLOAT / NULLIF(q."view_count", 0), 4)) AS "max_score_view_ratio"
    FROM
        STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
        JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q ON a."parent_id" = q."id"
    WHERE
        q."view_count" > 0
    GROUP BY
        a."parent_id"
)
SELECT
    q."id" AS "Question_ID",
    CAST(q."title" AS STRING) AS "Question_Title",
    LENGTH(q."body") AS "Question_Length",
    COALESCE(u."reputation", 0) AS "User_Reputation",
    COALESCE(u."up_votes", 0) - COALESCE(u."down_votes", 0) AS "Net_Votes",
    COALESCE(b."badge_count", 0) AS "Badge_Count"
FROM
    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
    LEFT JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" u ON q."owner_user_id" = u."id"
    LEFT JOIN (
        SELECT "user_id", COUNT(*) AS "badge_count"
        FROM STACKOVERFLOW.STACKOVERFLOW."BADGES"
        GROUP BY "user_id"
    ) b ON u."id" = b."user_id"
    LEFT JOIN answer_ratios ar ON q."id" = ar."question_id"
WHERE
    q."accepted_answer_id" IS NOT NULL
    OR COALESCE(ar."max_score_view_ratio", 0) > 0.01
ORDER BY
    LENGTH(q."body") DESC NULLS LAST
LIMIT 10;