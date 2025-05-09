WITH question_answer_times AS (
    SELECT
        q."id" AS "question_id",
        q."creation_date" AS "question_creation_date",
        MIN(a."creation_date") AS "first_answer_creation_date",
        MIN(a."creation_date") - q."creation_date" AS "time_difference"
    FROM
        "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
    JOIN
        "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" a
        ON q."id" = a."parent_id"
    GROUP BY
        q."id",
        q."creation_date"
),
questions_within_hour AS (
    SELECT
        "question_id",
        "question_creation_date",
        "first_answer_creation_date",
        "time_difference",
        CASE
            WHEN "time_difference" <= 3600000000 AND "time_difference" >= 0 THEN 1
            ELSE 0
        END AS "answered_within_hour"
    FROM
        question_answer_times
),
questions_with_day AS (
    SELECT
        "question_id",
        EXTRACT(DAYOFWEEK FROM TO_TIMESTAMP_NTZ("question_creation_date" / 1000000)) AS "day_of_week",
        UPPER(TRIM(TO_VARCHAR(TO_TIMESTAMP_NTZ("question_creation_date" / 1000000), 'DAY'))) AS "day_name",
        "answered_within_hour"
    FROM
        questions_within_hour
),
daily_stats AS (
    SELECT
        "day_of_week",
        "day_name",
        COUNT(*) AS "total_questions",
        SUM("answered_within_hour") AS "questions_answered_within_hour"
    FROM
        questions_with_day
    GROUP BY
        "day_of_week",
        "day_name"
)
SELECT
    "day_name",
    ROUND(("questions_answered_within_hour" * 100.0) / "total_questions", 4) AS "percentage"
FROM
    daily_stats
ORDER BY
    "percentage" DESC NULLS LAST
LIMIT 1 OFFSET 2;