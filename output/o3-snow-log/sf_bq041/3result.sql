WITH new_users_2021 AS (           -- users who signed-up in 2021
    SELECT
        "id"                                                    AS "user_id",
        TO_TIMESTAMP("creation_date" / 1000000)                 AS "signup_ts",
        DATE_TRUNC('MONTH', TO_TIMESTAMP("creation_date" / 1000000))
                                                                AS "signup_month"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE TO_TIMESTAMP("creation_date" / 1000000) >= '2021-01-01'
      AND TO_TIMESTAMP("creation_date" / 1000000) <  '2022-01-01'
),

user_first_question AS (           -- first question within 30 days of sign-up
    SELECT
        u."user_id",
        MIN(TO_TIMESTAMP(q."creation_date" / 1000000)) AS "first_q_ts"
    FROM new_users_2021 u
    JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
          ON q."owner_user_id" = u."user_id"
         AND TO_TIMESTAMP(q."creation_date" / 1000000)
             BETWEEN u."signup_ts" AND DATEADD('DAY', 30, u."signup_ts")
    GROUP BY u."user_id"
),

user_answer_after_question AS (    -- at least one answer > first question and ≤30 days after
    SELECT DISTINCT
        f."user_id"
    FROM user_first_question f
    JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
          ON a."owner_user_id" = f."user_id"
         AND TO_TIMESTAMP(a."creation_date" / 1000000) >
             f."first_q_ts"
         AND TO_TIMESTAMP(a."creation_date" / 1000000) <=
             DATEADD('DAY', 30, f."first_q_ts")
)

SELECT
    u."signup_month",
    COUNT(*)                                                      AS "total_new_users",
    ROUND(100.0 * COUNT(f."user_id") / COUNT(*), 4)               AS "pct_asked_question_30d",
    ROUND(
        100.0 * COUNT(a."user_id") / NULLIF(COUNT(f."user_id"),0),
        4
    )                                                             AS "pct_answer_after_first_question_30d"
FROM new_users_2021 u
LEFT JOIN user_first_question       f ON u."user_id" = f."user_id"
LEFT JOIN user_answer_after_question a ON u."user_id" = a."user_id"
GROUP BY u."signup_month"
ORDER BY u."signup_month";