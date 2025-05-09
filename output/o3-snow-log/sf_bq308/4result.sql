WITH questions_2021 AS (   -- all questions asked in 2021
    SELECT
        q."id"                                                    AS question_id ,
        TO_TIMESTAMP(q."creation_date" / 1000000)                 AS question_ts
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
    WHERE YEAR(TO_TIMESTAMP(q."creation_date" / 1000000)) = 2021
),
first_answers AS (          -- first answer time for every question
    SELECT
        a."parent_id"                                            AS question_id ,
        MIN(TO_TIMESTAMP(a."creation_date" / 1000000))           AS first_answer_ts
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    GROUP BY a."parent_id"
),
combined AS (               -- join questions to their first answer (if any)
    SELECT
        q.question_id ,
        q.question_ts ,
        DAYOFWEEK(q.question_ts)                                 AS dow ,      -- 1-Sunday … 7-Saturday
        TO_CHAR(q.question_ts , 'Dy')                            AS day_name ,
        CASE
            WHEN fa.first_answer_ts IS NOT NULL
                 AND DATEDIFF('second', q.question_ts , fa.first_answer_ts) <= 3600
            THEN 1 ELSE 0
        END                                                      AS answered_within_1h
    FROM questions_2021 q
    LEFT JOIN first_answers fa
           ON fa.question_id = q.question_id
)
SELECT
    dow                                                          AS "DAY_NUMBER" ,
    MIN(day_name)                                                AS "DAY_OF_WEEK" ,
    COUNT(*)                                                     AS "TOTAL_QUESTIONS" ,
    SUM(answered_within_1h)                                      AS "ANSWERED_WITHIN_1H" ,
    ROUND(SUM(answered_within_1h) * 100.0 / COUNT(*), 4)         AS "PERCENT_WITHIN_1H"
FROM combined
GROUP BY dow
ORDER BY dow;