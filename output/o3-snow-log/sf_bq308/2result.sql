WITH questions_2021 AS (      -- all questions asked in 2021
    SELECT
        "id"                                            AS question_id ,
        TO_TIMESTAMP( "creation_date" / 1000000 )       AS question_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE YEAR( TO_TIMESTAMP( "creation_date" / 1000000 ) ) = 2021
),
first_answers AS (           -- first answer time for every question (any year)
    SELECT
        "parent_id"                                   AS question_id ,
        MIN( TO_TIMESTAMP( "creation_date" / 1000000 ) )  AS first_answer_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    GROUP BY "parent_id"
),
question_stats AS (          -- combine and flag “answered within 1 hour”
    SELECT
        q.question_id ,
        q.question_ts ,
        DAYOFWEEK( q.question_ts )           AS weekday_num ,   -- 1-Sun … 7-Sat
        DAYNAME  ( q.question_ts )           AS weekday_name ,
        CASE
            WHEN a.first_answer_ts IS NOT NULL
                 AND DATEDIFF( 'second'
                               , q.question_ts
                               , a.first_answer_ts ) <= 3600
            THEN 1 ELSE 0
        END                                   AS answered_within_hour
    FROM questions_2021 q
    LEFT JOIN first_answers a
           ON a.question_id = q.question_id
)

SELECT
    weekday_name                       AS "DAY_OF_WEEK" ,
    COUNT(*)                           AS "TOTAL_QUESTIONS" ,
    SUM( answered_within_hour )        AS "ANSWERED_WITHIN_HOUR" ,
    ROUND(
        SUM( answered_within_hour ) * 100.0 / COUNT(*) , 4
    )                                  AS "PERCENT_WITHIN_HOUR"
FROM question_stats
GROUP BY
    weekday_num ,
    weekday_name
ORDER BY
    weekday_num;