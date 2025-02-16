-- Task: Calculate the number of questions that receive an answer within an hour for each day of the week.
SELECT
  FORMAT_DATE('%A', DATE_ADD(DATE '1970-01-04', INTERVAL EXTRACT(DAYOFWEEK FROM q.creation_date) - 1 DAY)) AS Day,
  COUNT(DISTINCT q.id) AS questions_answered_within_hour
FROM
  `bigquery-public-data.stackoverflow.posts_questions` AS q
JOIN
  `bigquery-public-data.stackoverflow.posts_answers` AS a
  ON q.id = a.parent_id
WHERE
  TIMESTAMP_DIFF(a.creation_date, q.creation_date, MINUTE) <= 60
GROUP BY
  Day
ORDER BY
  Day;