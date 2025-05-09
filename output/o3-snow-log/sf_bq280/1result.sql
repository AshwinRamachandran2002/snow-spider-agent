WITH answer_counts AS (
    SELECT
        "owner_user_id"        AS "user_id",
        COUNT(*)               AS "answer_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    WHERE "owner_user_id" IS NOT NULL
    GROUP BY "owner_user_id"
),
eligible_users AS (
    SELECT
        ac."user_id",
        ac."answer_cnt",
        u."display_name"
    FROM answer_counts ac
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
          ON ac."user_id" = u."id"
    WHERE u."reputation" > 10
)
SELECT
    "display_name"
FROM eligible_users
ORDER BY "answer_cnt" DESC NULLS LAST
LIMIT 1;