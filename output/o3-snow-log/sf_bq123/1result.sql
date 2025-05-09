WITH questions AS (                                                             -- every question
    SELECT 
        "id",
        "creation_date"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
),

first_answers AS (                                                             -- first answer per question
    SELECT 
        "parent_id"                       AS question_id,
        MIN("creation_date")              AS first_answer_date
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    GROUP BY "parent_id"
),

per_question AS (                                                              -- flag if answered within one hour
    SELECT
        TO_CHAR( DAYNAME( TO_TIMESTAMP(q."creation_date" / 1000000) ) ) 
                                            AS day_of_week,
        CASE 
            WHEN fa.first_answer_date IS NOT NULL 
             AND (fa.first_answer_date - q."creation_date") <= 3600000000      -- 3 600 s in µs
            THEN 1 ELSE 0 
        END                                AS answered_in_hour
    FROM questions q
    LEFT JOIN first_answers fa
           ON fa.question_id = q."id"
),

per_day AS (                                                                   -- percentage per day
    SELECT
        day_of_week,
        ROUND( 100.0 * SUM(answered_in_hour) / COUNT(*) , 4) AS pct_in_hour
    FROM per_question
    GROUP BY day_of_week
),

ranked AS (                                                                    -- rank by percentage
    SELECT
        day_of_week,
        pct_in_hour,
        DENSE_RANK() OVER (ORDER BY pct_in_hour DESC NULLS LAST) AS rnk
    FROM per_day
)

SELECT
    day_of_week,
    pct_in_hour
FROM ranked
WHERE rnk = 3;