WITH questions AS (
    SELECT
        "id" AS question_id,
        "creation_date" AS question_creation_date,
        DAYNAME(TO_TIMESTAMP("creation_date" / 1000000)) AS "Day_of_Week",
        DAYOFWEEKISO(TO_TIMESTAMP("creation_date" / 1000000)) AS day_num
    FROM
        STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE
        "creation_date" BETWEEN 1609459200000000 AND 1640995199000000
),
first_answers AS (
    SELECT
        "parent_id" AS question_id,
        MIN("creation_date") AS first_answer_date
    FROM
        STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    GROUP BY
        "parent_id"
),
questions_with_answers AS (
    SELECT
        q.question_id,
        q.question_creation_date,
        q."Day_of_Week",
        q.day_num,
        fa.first_answer_date,
        (fa.first_answer_date - q.question_creation_date) / 1000000 AS time_to_answer_seconds
    FROM
        questions q
    LEFT JOIN
        first_answers fa ON q.question_id = fa.question_id
)
SELECT
    qwa."Day_of_Week",
    COUNT(*) AS "Questions_Asked",
    COUNT(CASE WHEN qwa.first_answer_date IS NOT NULL AND qwa.time_to_answer_seconds <= 3600 THEN 1 END) AS "Answered_Within_One_Hour",
    ROUND(COUNT(CASE WHEN qwa.first_answer_date IS NOT NULL AND qwa.time_to_answer_seconds <= 3600 THEN 1 END) * 100.0 / COUNT(*), 4) AS "Percentage_Answered"
FROM
    questions_with_answers qwa
GROUP BY
    qwa."Day_of_Week", qwa.day_num
ORDER BY
    qwa.day_num;