WITH new_users_2021 AS (           -- all users that signed-up in 2021
    SELECT
        "id"                                              AS user_id ,
        TO_TIMESTAMP( "creation_date" / 1000000 )         AS signup_ts ,
        DATE_TRUNC( 'month'
                   ,TO_TIMESTAMP( "creation_date" / 1000000 )
                  )                                       AS signup_month
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE DATE_PART( 'year'
                    ,TO_TIMESTAMP( "creation_date" / 1000000 )
                   ) = 2021
),

questions AS (                     -- every question
    SELECT
        "owner_user_id"                                   AS user_id ,
        TO_TIMESTAMP( "creation_date" / 1000000 )         AS question_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
),

answers AS (                       -- every answer
    SELECT
        "owner_user_id"                                   AS user_id ,
        TO_TIMESTAMP( "creation_date" / 1000000 )         AS answer_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
),

-- first question asked within 30 days of sign-up
user_first_question_30d AS (
    SELECT
        u.user_id ,
        u.signup_month ,
        MIN( q.question_ts )                              AS first_question_ts
    FROM new_users_2021          u
    JOIN questions               q
      ON q.user_id = u.user_id
     AND q.question_ts BETWEEN u.signup_ts
                           AND u.signup_ts + INTERVAL '30 days'
    GROUP BY u.user_id , u.signup_month
),

-- user answered (after that first question) within the next 30 days
user_answer_after_question_30d AS (
    SELECT DISTINCT
        fq.user_id ,
        fq.signup_month
    FROM user_first_question_30d  fq
    JOIN answers                  a
      ON  a.user_id = fq.user_id
     AND a.answer_ts  >  fq.first_question_ts
     AND a.answer_ts  <= fq.first_question_ts + INTERVAL '30 days'
)

SELECT
    u.signup_month                                       AS month_start ,
    COUNT( u.user_id )                                   AS total_new_users ,
    COUNT( fq.user_id )                                  AS new_users_asked_question_30d ,
    COUNT( fa.user_id )                                  AS new_users_answer_after_question_30d ,
    ROUND( 100.0 * COUNT( fq.user_id )
                 / NULLIF( COUNT( u.user_id ) , 0 ) , 4) AS pct_asked_question_30d ,
    ROUND( 100.0 * COUNT( fa.user_id )
                 / NULLIF( COUNT( fq.user_id ) , 0 ) , 4) AS pct_answer_after_question_30d
FROM new_users_2021                 u
LEFT JOIN user_first_question_30d   fq ON fq.user_id = u.user_id
LEFT JOIN user_answer_after_question_30d fa ON fa.user_id = u.user_id
GROUP BY u.signup_month
ORDER BY u.signup_month;