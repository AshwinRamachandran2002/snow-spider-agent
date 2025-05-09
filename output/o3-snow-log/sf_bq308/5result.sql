WITH questions_2021 AS (
    SELECT
        q."id"                                            AS question_id,
        q."creation_date"                                 AS q_create_micro,
        TO_TIMESTAMP_LTZ(q."creation_date" / 1000000)     AS q_ts,
        TO_CHAR(TO_TIMESTAMP_LTZ(q."creation_date" / 1000000), 'DY') AS day_of_week
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
    WHERE DATE_PART('year', TO_TIMESTAMP_LTZ(q."creation_date" / 1000000)) = 2021
),

answered_within_hour AS (
    SELECT
        q.question_id
    FROM questions_2021 q
    WHERE EXISTS (
        SELECT 1
        FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
        WHERE a."parent_id" = q.question_id
          AND a."creation_date" <= q.q_create_micro + 3600 * 1000000   -- within 1 hour (microseconds)
    )
),

daily_stats AS (
    SELECT
        q.day_of_week,
        COUNT(*)                                AS total_questions,
        COUNT(awh.question_id)                  AS answered_within_hour
    FROM questions_2021 q
    LEFT JOIN answered_within_hour awh
           ON q.question_id = awh.question_id
    GROUP BY q.day_of_week
)

SELECT
    day_of_week,
    total_questions,
    answered_within_hour,
    ROUND(answered_within_hour * 100.0 / NULLIF(total_questions, 0), 4) AS pct_answered_within_hour
FROM daily_stats
ORDER BY DECODE(day_of_week,
                'MON',1,'TUE',2,'WED',3,'THU',4,'FRI',5,'SAT',6,'SUN',7);