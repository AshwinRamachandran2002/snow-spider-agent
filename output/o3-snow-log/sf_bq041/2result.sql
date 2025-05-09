/*  Monthly stats for users who signed-up in 2021                                         
    – new users per month                                                                 
    – % of those new users who asked ≥1 question within 30 days of sign-up               
    – for those askers, % who then posted ≥1 answer after their first question           
      and within 30 days of that first question                                           */

WITH new_users AS (          -- all users created in 2021
    SELECT  "id"                                                AS user_id ,
            TO_TIMESTAMP("creation_date"/1000000)               AS signup_ts ,
            DATE_TRUNC('month', TO_TIMESTAMP("creation_date"/1000000)) AS signup_month
    FROM    STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE   TO_TIMESTAMP("creation_date"/1000000) >= '2021-01-01'
      AND   TO_TIMESTAMP("creation_date"/1000000) <  '2022-01-01'
),

questions AS (               -- every question with its owner and time
    SELECT  "owner_user_id"                                     AS user_id ,
            TO_TIMESTAMP("creation_date"/1000000)               AS question_ts
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE   "owner_user_id" IS NOT NULL
),

answers AS (                 -- every answer with its owner and time
    SELECT  "owner_user_id"                                     AS user_id ,
            TO_TIMESTAMP("creation_date"/1000000)               AS answer_ts
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    WHERE   "owner_user_id" IS NOT NULL
),

-- first question posted within 30 days of sign-up
questions_within_30 AS (
    SELECT  n.user_id ,
            n.signup_month ,
            MIN(q.question_ts)                                  AS first_question_ts
    FROM    new_users n
    JOIN    questions q
           ON q.user_id = n.user_id
          AND q.question_ts >= n.signup_ts
          AND q.question_ts <= n.signup_ts + INTERVAL '30 days'
    GROUP BY n.user_id , n.signup_month
),

-- users who answered after that first question, within the next 30 days
answers_within_30_after_q AS (
    SELECT  DISTINCT q.user_id , q.signup_month
    FROM    questions_within_30        q
    JOIN    answers                    a
           ON a.user_id = q.user_id
          AND a.answer_ts  > q.first_question_ts
          AND a.answer_ts <= q.first_question_ts + INTERVAL '30 days'
)

SELECT  TO_CHAR(n.signup_month, 'YYYY-MM')                       AS month ,
        COUNT(*)                                                 AS new_users ,
        ROUND(
            100.0 * COUNT(CASE WHEN q.user_id IS NOT NULL THEN 1 END)
            / COUNT(*) , 4)                                      AS pct_asked_question_within_30 ,
        ROUND(
            100.0 * COUNT(CASE WHEN a.user_id IS NOT NULL THEN 1 END)
            / NULLIF( COUNT(CASE WHEN q.user_id IS NOT NULL THEN 1 END) , 0 )
        , 4)                                                     AS pct_of_askers_who_answered_within_30
FROM    new_users n
LEFT JOIN questions_within_30        q ON n.user_id = q.user_id
LEFT JOIN answers_within_30_after_q  a ON n.user_id = a.user_id
GROUP BY n.signup_month
ORDER BY n.signup_month;