WITH users_2021 AS (           -- all users that signed-up in 2021
    SELECT  "id"                                            AS user_id ,
            TO_TIMESTAMP_NTZ("creation_date"/1000000)       AS signup_ts ,
            DATE_TRUNC('month', TO_TIMESTAMP_NTZ("creation_date"/1000000)) AS signup_month
    FROM    STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE   TO_TIMESTAMP_NTZ("creation_date"/1000000) >= '2021-01-01'
      AND   TO_TIMESTAMP_NTZ("creation_date"/1000000) <  '2022-01-01'
),
first_questions AS (          -- first question asked within 30 days of sign-up
    SELECT  u.user_id ,
            MIN(TO_TIMESTAMP_NTZ(q."creation_date"/1000000)) AS first_question_ts
    FROM    users_2021               u
    LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
           ON q."owner_user_id" = u.user_id
          AND TO_TIMESTAMP_NTZ(q."creation_date"/1000000) >= u.signup_ts
          AND TO_TIMESTAMP_NTZ(q."creation_date"/1000000) <= u.signup_ts + INTERVAL '30 day'
    GROUP BY u.user_id
),
user_flags AS (               -- per user activity flags
    SELECT  u.signup_month ,
            u.user_id ,
            CASE WHEN fq.first_question_ts IS NOT NULL THEN 1 ELSE 0 END               AS asked_flag ,
            CASE
                 WHEN fq.first_question_ts IS NOT NULL
                  AND EXISTS ( SELECT 1
                               FROM  STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
                               WHERE a."owner_user_id" = u.user_id
                                 AND TO_TIMESTAMP_NTZ(a."creation_date"/1000000)  >  fq.first_question_ts
                                 AND TO_TIMESTAMP_NTZ(a."creation_date"/1000000) <= fq.first_question_ts + INTERVAL '30 day'
                             )
                 THEN 1 ELSE 0
            END                                                                         AS answered_flag
    FROM    users_2021   u
    LEFT JOIN first_questions fq ON fq.user_id = u.user_id
)
SELECT  signup_month ,
        COUNT(*)                                                  AS new_users ,
        ROUND(100.0 * SUM(asked_flag) / COUNT(*), 4)              AS pct_asked_within_30 ,
        ROUND(100.0 * SUM(CASE WHEN asked_flag = 1 THEN answered_flag ELSE 0 END)
                    / NULLIF(SUM(asked_flag),0) , 4)              AS pct_asked_then_answered_within_30
FROM    user_flags
GROUP BY signup_month
ORDER BY signup_month;