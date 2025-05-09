WITH questions_2021 AS (        -- every question posted in calendar year 2021
    SELECT
        q."id"                             AS question_id ,
        q."creation_date"                  AS q_create_micro ,
        DAYNAME( TO_TIMESTAMP( q."creation_date" / 1000000 ) ) AS day_of_week
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
    WHERE EXTRACT( YEAR FROM TO_TIMESTAMP( q."creation_date" / 1000000 ) ) = 2021
),

first_answers AS (              -- first answer (if any) for every question
    SELECT
        a."parent_id"                     AS question_id ,
        MIN( a."creation_date" )          AS first_answer_micro
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
    GROUP BY a."parent_id"
),

q_with_answer_flag AS (
    SELECT
        q.day_of_week ,
        CASE
            WHEN fa.first_answer_micro IS NOT NULL
                 AND fa.first_answer_micro - q.q_create_micro <= 3600000000   -- 1 hour in µs
            THEN 1 ELSE 0
        END AS answered_within_hour
    FROM questions_2021 q
    LEFT JOIN first_answers fa
           ON fa.question_id = q.question_id
)

SELECT
    day_of_week                                    AS "DAY_OF_WEEK",
    COUNT(*)                                       AS "TOTAL_QUESTIONS",
    SUM( answered_within_hour )                    AS "ANSWERED_WITHIN_1_HOUR",
    ROUND( SUM( answered_within_hour )::FLOAT
           / COUNT(*) * 100 , 2)                   AS "PCT_ANSWERED_WITHIN_1_HOUR"
FROM q_with_answer_flag
GROUP BY day_of_week
ORDER BY
    CASE day_of_week
         WHEN 'Monday'    THEN 1
         WHEN 'Tuesday'   THEN 2
         WHEN 'Wednesday' THEN 3
         WHEN 'Thursday'  THEN 4
         WHEN 'Friday'    THEN 5
         WHEN 'Saturday'  THEN 6
         WHEN 'Sunday'    THEN 7
    END;