WITH new_users AS (                               -- users who signed-up in 2021
    SELECT  "id" AS user_id,
            TO_TIMESTAMP_NTZ("creation_date"/1e6)                       AS signup_ts,
            DATE_TRUNC('month', TO_TIMESTAMP_NTZ("creation_date"/1e6))  AS signup_month
    FROM    STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE   TO_TIMESTAMP_NTZ("creation_date"/1e6)
            BETWEEN '2021-01-01' AND '2021-12-31 23:59:59.999'
),                                                -- all questions
questions AS (
    SELECT  "owner_user_id" AS user_id,
            TO_TIMESTAMP_NTZ("creation_date"/1e6) AS question_ts
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
),                                                -- all answers
answers AS (
    SELECT  "owner_user_id" AS user_id,
            TO_TIMESTAMP_NTZ("creation_date"/1e6) AS answer_ts
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
),                                                -- first question ≤30 days after sign-up
first_question AS (
    SELECT   q.user_id,
             MIN(q.question_ts) AS first_q_ts
    FROM     questions q
    JOIN     new_users u
           ON q.user_id = u.user_id
          AND q.question_ts BETWEEN u.signup_ts AND DATEADD(day, 30, u.signup_ts)
    GROUP BY q.user_id
),                                                -- any answer after that question, within 30 days
answer_after AS (
    SELECT DISTINCT a.user_id
    FROM   first_question fq
    JOIN   answers a
          ON a.user_id = fq.user_id
         AND a.answer_ts >  fq.first_q_ts
         AND a.answer_ts <= DATEADD(day, 30, fq.first_q_ts)
)
SELECT
    u.signup_month                                                        AS month,
    COUNT(*)                                                              AS total_new_users,
    ROUND(COUNT(fq.user_id)::FLOAT / COUNT(*) * 100, 4)                   AS pct_with_question_30d,
    ROUND(COUNT(aa.user_id)::FLOAT / NULLIF(COUNT(fq.user_id),0) * 100,4) AS pct_ans_after_q_30d
FROM        new_users      u
LEFT JOIN   first_question fq ON fq.user_id = u.user_id
LEFT JOIN   answer_after   aa ON aa.user_id = u.user_id
GROUP BY     u.signup_month
ORDER BY     u.signup_month;