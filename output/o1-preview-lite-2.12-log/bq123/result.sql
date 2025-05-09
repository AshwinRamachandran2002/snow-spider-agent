WITH
  total_questions AS (
    SELECT
      EXTRACT(DAYOFWEEK FROM creation_date) AS day_of_week,
      COUNT(*) AS total_questions
    FROM
      `bigquery-public-data.stackoverflow.posts_questions`
    GROUP BY
      day_of_week
  ),
  questions_with_fast_answer AS (
    SELECT
      EXTRACT(DAYOFWEEK FROM q.creation_date) AS day_of_week,
      COUNT(DISTINCT q.id) AS fast_answer_questions
    FROM
      `bigquery-public-data.stackoverflow.posts_questions` AS q
    JOIN (
      SELECT
        parent_id,
        MIN(creation_date) AS first_answer_date
      FROM
        `bigquery-public-data.stackoverflow.posts_answers`
      GROUP BY
        parent_id
    ) AS a
    ON q.id = a.parent_id
    WHERE
      TIMESTAMP_DIFF(a.first_answer_date, q.creation_date, MINUTE) <= 60
    GROUP BY
      day_of_week
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
  END AS Day_of_week,
  ROUND((fast_answer_questions * 100.0) / total_questions, 4) AS Percentage
FROM
  (
    SELECT
      t.day_of_week,
      t.total_questions,
      COALESCE(fa.fast_answer_questions, 0) AS fast_answer_questions
    FROM
      total_questions t
    LEFT JOIN
      questions_with_fast_answer fa
    ON
      t.day_of_week = fa.day_of_week
  )
ORDER BY
  Percentage DESC
LIMIT
  1 OFFSET 2;