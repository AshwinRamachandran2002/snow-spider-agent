WITH answer_data AS (
  SELECT
    q.id AS question_id,
    q.creation_date,
    FORMAT_TIMESTAMP('%A', q.creation_date) AS Day_of_week,
    MIN(a.creation_date) AS min_answer_date
  FROM
    `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN
    `bigquery-public-data.stackoverflow.posts_answers` AS a
  ON
    q.id = a.parent_id
  GROUP BY
    q.id, q.creation_date, Day_of_week
)

SELECT
  Day_of_week,
  ROUND(
    (SUM(CASE WHEN min_answer_date IS NOT NULL AND TIMESTAMP_DIFF(min_answer_date, creation_date, SECOND) <= 3600 THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
    4
  ) AS Percentage
FROM
  answer_data
GROUP BY
  Day_of_week
ORDER BY
  Percentage DESC
LIMIT 1 OFFSET 2