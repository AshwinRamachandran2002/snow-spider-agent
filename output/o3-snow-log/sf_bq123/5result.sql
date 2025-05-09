WITH questions AS (
    SELECT  "id"                                                                    AS question_id ,
            TO_TIMESTAMP("creation_date" / 1000000)                                 AS q_ts ,
            DAYNAME(TO_TIMESTAMP("creation_date" / 1000000))                        AS day_name
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
),
first_answers AS (
    SELECT  "parent_id"                                                             AS question_id ,
            MIN(TO_TIMESTAMP("creation_date" / 1000000))                            AS first_ans_ts
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    GROUP BY "parent_id"
),
qa AS (
    SELECT  q.day_name ,
            CASE 
                 WHEN a.first_ans_ts IS NOT NULL 
                      AND DATEDIFF('second' , q.q_ts , a.first_ans_ts) <= 3600 
                 THEN 1 
                 ELSE 0 
            END                                                                     AS answered_within_hour
    FROM    questions q
    LEFT JOIN first_answers a
           ON q.question_id = a.question_id
),
day_stats AS (
    SELECT  day_name ,
            ROUND( 100.0 * SUM(answered_within_hour) / COUNT(*) , 4)                AS pct_within_hour
    FROM    qa
    GROUP BY day_name
)
SELECT  day_name ,
        pct_within_hour
FROM    day_stats
QUALIFY DENSE_RANK() OVER (ORDER BY pct_within_hour DESC NULLS LAST) = 3;