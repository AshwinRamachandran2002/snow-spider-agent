WITH "answers_per_user" AS (
    SELECT
        "owner_user_id" AS "user_id",
        COUNT(*)        AS "answer_count"
    FROM
        STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    WHERE
        "owner_user_id" IS NOT NULL
    GROUP BY
        "owner_user_id"
)
SELECT
    u."display_name"
FROM
    "answers_per_user" apu
    JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" u
      ON apu."user_id" = u."id"
WHERE
    u."reputation" > 10
ORDER BY
    apu."answer_count" DESC NULLS LAST
LIMIT 1;