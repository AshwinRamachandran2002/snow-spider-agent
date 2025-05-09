WITH questions AS (
    SELECT
        "id"                                  AS question_id,
        TO_TIMESTAMP("creation_date"/1000000) AS question_ts,
        TO_CHAR(TO_TIMESTAMP("creation_date"/1000000), 'DY') AS day_of_week   -- SUN, MON, …
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
),
first_answers AS (
    SELECT
        "parent_id"                           AS question_id,
        MIN(TO_TIMESTAMP("creation_date"/1000000)) AS first_answer_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    GROUP BY "parent_id"
),
joined AS (       -- tie the questions to their earliest answer (if any)
    SELECT
        q.day_of_week,
        CASE 
            WHEN a.first_answer_ts IS NOT NULL
                 AND DATEDIFF('second', q.question_ts, a.first_answer_ts) <= 3600
            THEN 1 ELSE 0
        END AS answered_within_hour
    FROM questions q
    LEFT JOIN first_answers a
           ON a.question_id = q.question_id
),
day_stats AS (    -- percentage per day-of-week
    SELECT
        day_of_week,
        SUM(answered_within_hour)::FLOAT / COUNT(*) * 100   AS pct_answer_within_hour
    FROM joined
    GROUP BY day_of_week
    ORDER BY pct_answer_within_hour DESC NULLS LAST
)
-- pick the day with the 3rd-highest percentage
SELECT
    day_of_week,
    ROUND(pct_answer_within_hour, 4) AS pct_answer_within_hour
FROM day_stats
ORDER BY pct_answer_within_hour DESC NULLS LAST
LIMIT 1 OFFSET 2;     -- 0-based offset ⇒ the 3rd row