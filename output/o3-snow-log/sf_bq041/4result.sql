WITH new_users AS (   -- every user created in 2021
    SELECT  "id"                                          AS user_id ,
            TO_TIMESTAMP("creation_date"/1000000)         AS signup_ts ,
            TO_CHAR(TO_TIMESTAMP("creation_date"/1000000),'YYYY-MM') AS yr_month
    FROM    STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE   TO_TIMESTAMP("creation_date"/1000000) >= '2021-01-01'
      AND   TO_TIMESTAMP("creation_date"/1000000) <  '2022-01-01'
),
questions AS (         -- all questions
    SELECT  "owner_user_id" AS user_id ,
            TO_TIMESTAMP("creation_date"/1000000) AS q_ts
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE   "owner_user_id" IS NOT NULL
),
answers AS (           -- all answers
    SELECT  "owner_user_id" AS user_id ,
            TO_TIMESTAMP("creation_date"/1000000) AS a_ts
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    WHERE   "owner_user_id" IS NOT NULL
),
first_question AS (    -- first question ≤30 days after sign-up
    SELECT  n.user_id ,
            MIN(q.q_ts) AS first_q_ts
    FROM    new_users n
    JOIN    questions  q
           ON q.user_id = n.user_id
          AND q.q_ts   <= DATEADD(day,30,n.signup_ts)
    GROUP BY n.user_id
),
askers AS (            -- users who asked within 30 days
    SELECT  f.user_id ,
            f.first_q_ts ,
            n.yr_month
    FROM    first_question f
    JOIN    new_users      n USING (user_id)
),
answerers AS (         -- of those askers: answered >first_q and ≤30 days after it
    SELECT  DISTINCT a.user_id
    FROM    askers  ak
    JOIN    answers a
           ON a.user_id = ak.user_id
          AND a.a_ts   >  ak.first_q_ts
          AND a.a_ts   <= DATEADD(day,30,ak.first_q_ts)
)
SELECT  n.yr_month                                                  AS month ,
        COUNT(*)                                                    AS total_new_users ,
        ROUND( COUNT(DISTINCT ak.user_id)*100.0 / COUNT(*) , 4)     AS pct_asked_within_30d ,
        ROUND( CASE 
                 WHEN COUNT(DISTINCT ak.user_id)=0 THEN NULL
                 ELSE COUNT(DISTINCT ans.user_id)*100.0
                      / COUNT(DISTINCT ak.user_id)
               END , 4)                                             AS pct_answered_within_30d_after_first_q
FROM    new_users  n
LEFT JOIN askers    ak  ON ak.user_id  = n.user_id
LEFT JOIN answerers ans ON ans.user_id = n.user_id
GROUP BY n.yr_month
ORDER BY n.yr_month;