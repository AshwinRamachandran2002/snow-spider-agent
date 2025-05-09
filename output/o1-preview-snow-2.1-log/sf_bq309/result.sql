SELECT
    q."id" AS "Question_ID",
    q."title" AS "Question_Title",
    LENGTH(q."body") AS "Question_Length",
    u."reputation" AS "User_Reputation",
    (u."up_votes" - u."down_votes") AS "Net_Votes",
    COALESCE(b."badge_count", 0) AS "Badge_Count"
FROM
    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
JOIN
    STACKOVERFLOW.STACKOVERFLOW."USERS" u ON q."owner_user_id" = u."id"
LEFT JOIN
    (
        SELECT
            ba."user_id",
            COUNT(*) AS "badge_count"
        FROM
            STACKOVERFLOW.STACKOVERFLOW."BADGES" ba
        GROUP BY
            ba."user_id"
    ) b ON u."id" = b."user_id"
LEFT JOIN
    (
        SELECT
            a."parent_id",
            MAX(a."score") AS "max_answer_score"
        FROM
            STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
        GROUP BY
            a."parent_id"
    ) a_max ON q."id" = a_max."parent_id"
WHERE
    q."accepted_answer_id" IS NOT NULL
    OR (
        q."view_count" > 0
        AND (a_max."max_answer_score" / q."view_count") > 0.01
    )
ORDER BY
    LENGTH(q."body") DESC NULLS LAST
LIMIT
    10;