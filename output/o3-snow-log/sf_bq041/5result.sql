WITH new_users AS (    -- every user that signed-up in 2021
    SELECT
        "id"                                           AS user_id ,
        TO_TIMESTAMP("creation_date"/1000000)          AS signup_ts ,
        DATE_TRUNC('month', TO_TIMESTAMP("creation_date"/1000000))
                                                      AS signup_month
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE YEAR(TO_TIMESTAMP("creation_date"/1000000)) = 2021
),

questions AS (        -- every question with its owner and time-stamp
    SELECT
        "owner_user_id"                               AS user_id ,
        TO_TIMESTAMP("creation_date"/1000000)         AS q_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE "owner_user_id" IS NOT NULL
),

first_question AS (    -- first question asked within 30 days of sign-up
    SELECT
        nu.user_id ,
        MIN(q.q_ts)                                   AS first_q_ts
    FROM new_users   nu
    JOIN questions   q
          ON q.user_id = nu.user_id
         AND q.q_ts  >= nu.signup_ts
         AND q.q_ts  <= nu.signup_ts + INTERVAL '30 day'
    GROUP BY nu.user_id
),

answers AS (           -- every answer with its owner and time-stamp
    SELECT
        "owner_user_id"                               AS user_id ,
        TO_TIMESTAMP("creation_date"/1000000)         AS a_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    WHERE "owner_user_id" IS NOT NULL
),

answered_after_question AS (   -- at least one answer within 30 days *after* first question
    SELECT DISTINCT
        fq.user_id
    FROM first_question fq
    JOIN answers        a
          ON a.user_id = fq.user_id
         AND a.a_ts    >  fq.first_q_ts
         AND a.a_ts    <= fq.first_q_ts + INTERVAL '30 day'
)

SELECT
    nu.signup_month                                          AS month ,
    COUNT(*)                                                 AS total_new_users ,

    ROUND(
        100.0 * SUM( CASE WHEN fq.first_q_ts IS NOT NULL THEN 1 ELSE 0 END )
        / COUNT(*)
    , 4)                                                     AS pct_asked_within_30 ,

    ROUND(
        100.0 * SUM( CASE WHEN aa.user_id IS NOT NULL THEN 1 ELSE 0 END )
        / NULLIF( SUM( CASE WHEN fq.first_q_ts IS NOT NULL THEN 1 ELSE 0 END ), 0 )
    , 4)                                                     AS pct_answered_after_question_within_30

FROM          new_users               nu
LEFT JOIN     first_question          fq  ON fq.user_id = nu.user_id
LEFT JOIN     answered_after_question aa  ON aa.user_id = nu.user_id
GROUP BY      nu.signup_month
ORDER BY      nu.signup_month;