WITH questions AS (
    SELECT
        "id"                                AS question_id,
        TO_TIMESTAMP("creation_date" / 1000000) AS q_ts,
        DAYNAME(TO_TIMESTAMP("creation_date" / 1000000)) AS weekday
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
),
earliest_answers AS (
    SELECT
        "parent_id"                         AS question_id,
        MIN("creation_date")                AS earliest_answer_creation
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    GROUP BY "parent_id"
),
joined AS (
    SELECT
        q.weekday,
        q.q_ts,
        TO_TIMESTAMP(e.earliest_answer_creation / 1000000) AS a_ts
    FROM questions q
    LEFT JOIN earliest_answers e
           ON q.question_id = e.question_id
),
stats AS (
    SELECT
        weekday,
        COUNT(*) AS total_questions,
        SUM(
            CASE
                WHEN a_ts IS NOT NULL
                     AND DATEDIFF('second', q_ts, a_ts) <= 3600
                THEN 1 ELSE 0
            END
        ) AS answered_within_hour
    FROM joined
    GROUP BY weekday
),
ranked AS (
    SELECT
        weekday,
        answered_within_hour * 100.0 / total_questions AS pct_within_hour,
        ROW_NUMBER() OVER (ORDER BY answered_within_hour * 100.0 / total_questions DESC, weekday) AS rn
    FROM stats
)
SELECT
    weekday,
    ROUND(pct_within_hour, 4) AS percentage_within_hour
FROM ranked
WHERE rn = 3;