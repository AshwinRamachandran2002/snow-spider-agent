WITH new_users AS (   -- users who signed up in 2021
    SELECT
        "id"                                                    AS user_id,
        TO_TIMESTAMP("creation_date" / 1000000)                 AS signup_ts,
        DATE_TRUNC('month', TO_TIMESTAMP("creation_date" / 1000000)) AS signup_month
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE TO_TIMESTAMP("creation_date" / 1000000)
          BETWEEN '2021-01-01' AND '2021-12-31 23:59:59.999'
),

questions AS (        -- all questions with a valid owner
    SELECT
        "owner_user_id"                                         AS user_id,
        TO_TIMESTAMP("creation_date" / 1000000)                 AS question_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE "owner_user_id" IS NOT NULL
),

answers AS (          -- all answers with a valid owner
    SELECT
        "owner_user_id"                                         AS user_id,
        TO_TIMESTAMP("creation_date" / 1000000)                 AS answer_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    WHERE "owner_user_id" IS NOT NULL
),

user_first_question AS (   -- first question ≤ 30 days after sign-up
    SELECT
        n.user_id,
        n.signup_month,
        MIN(q.question_ts)                                      AS first_q_ts
    FROM new_users n
    JOIN questions q
      ON q.user_id = n.user_id
     AND q.question_ts <= DATEADD(day, 30, n.signup_ts)
    GROUP BY n.user_id, n.signup_month
),

answer_after_question AS ( -- at least one answer after first question and within 30 days
    SELECT
        ufq.user_id,
        ufq.signup_month
    FROM user_first_question ufq
    JOIN answers a
      ON a.user_id = ufq.user_id
     AND a.answer_ts  >  ufq.first_q_ts
     AND a.answer_ts <= DATEADD(day, 30, ufq.first_q_ts)
    GROUP BY ufq.user_id, ufq.signup_month
)

SELECT
    n.signup_month                                   AS signup_month,
    COUNT(*)                                         AS new_users,
    COUNT(DISTINCT ufq.user_id)                      AS users_asked_within_30,
    ROUND(100.0 * COUNT(DISTINCT ufq.user_id) / COUNT(*), 4)
                                                     AS pct_asked_within_30,
    COUNT(DISTINCT aq.user_id)                       AS ask_then_answer,
    ROUND(
          100.0 * COUNT(DISTINCT aq.user_id)
          / NULLIF(COUNT(DISTINCT ufq.user_id), 0)
         , 4)                                        AS pct_answer_after_ask
FROM new_users n
LEFT JOIN user_first_question   ufq ON n.user_id = ufq.user_id
LEFT JOIN answer_after_question aq  ON n.user_id = aq.user_id
GROUP BY n.signup_month
ORDER BY n.signup_month;