SELECT
  Day_of_week,
  COUNT(*) AS Questions_Asked,
  SUM(CASE WHEN time_to_first_answer_minutes <= 60 THEN 1 ELSE 0 END) AS Questions_Answered_Within_One_Hour,
  ROUND(100 * SUM(CASE WHEN time_to_first_answer_minutes <= 60 THEN 1 ELSE 0 END) / COUNT(*), 4) AS Percentage_Answered_Within_One_Hour
FROM (
  SELECT
    FORMAT_DATE('%A', DATE(q.creation_date)) AS Day_of_week,
    q.id AS question_id,
    MIN(TIMESTAMP_DIFF(a.creation_date, q.creation_date, MINUTE)) AS time_to_first_answer_minutes
  FROM
    `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN
    `bigquery-public-data.stackoverflow.posts_answers` AS a
  ON
    q.id = a.parent_id
  WHERE
    q.creation_date BETWEEN '2021-01-01' AND '2021-12-31'
  GROUP BY
    Day_of_week, q.id
)
GROUP BY
  Day_of_week
ORDER BY
  Day_of_week;