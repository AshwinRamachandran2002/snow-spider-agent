SELECT
    q."id" AS "Question_ID",
    CAST(REPLACE(q."title", '"""', '') AS STRING) AS "Question_Title",
    LENGTH(q."body") AS "Question_Length",
    u."reputation" AS "User_Reputation",
    (u."up_votes" - u."down_votes") AS "Net_Votes",
    COALESCE(b."Badge_Count", 0) AS "Badge_Count"
FROM
    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
JOIN
    STACKOVERFLOW.STACKOVERFLOW."USERS" u
    ON q."owner_user_id" = u."id"
LEFT JOIN (
    SELECT
        "user_id",
        COUNT(*) AS "Badge_Count"
    FROM
        STACKOVERFLOW.STACKOVERFLOW."BADGES"
    GROUP BY
        "user_id"
) b
    ON u."id" = b."user_id"
LEFT JOIN (
    SELECT
        "parent_id" AS "Question_ID",
        MAX("score") AS "Max_Answer_Score"
    FROM
        STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    GROUP BY
        "parent_id"
) ans
    ON q."id" = ans."Question_ID"
WHERE
    q."body" IS NOT NULL
    AND (
        q."accepted_answer_id" IS NOT NULL
        OR (
            ans."Max_Answer_Score" IS NOT NULL
            AND q."view_count" > 0
            AND ROUND(ans."Max_Answer_Score" / q."view_count", 4) > 0.01
        )
    )
ORDER BY
    LENGTH(q."body") DESC NULLS LAST
LIMIT 10;