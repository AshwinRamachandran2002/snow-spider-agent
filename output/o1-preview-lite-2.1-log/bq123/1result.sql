WITH first_answers AS (
    SELECT
        q.`id` AS question_id,
        EXTRACT(DAYOFWEEK FROM q.`creation_date`) AS day_of_week,
        TIMESTAMP_DIFF(MIN(a.`creation_date`), q.`creation_date`, MINUTE) AS time_to_first_answer_minutes
    FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
    JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON q.`id` = a.`parent_id`
    GROUP BY question_id, day_of_week, q.`creation_date`
),
percentages AS (
    SELECT
        day_of_week,
        ROUND(SUM(CASE WHEN time_to_first_answer_minutes <= 60 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 4) AS percentage_within_hour
    FROM first_answers
    GROUP BY day_of_week
)
SELECT
    CASE day_of_week
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS Day,
    percentage_within_hour AS Percentage
FROM percentages
ORDER BY percentage_within_hour DESC
LIMIT 1 OFFSET 2;