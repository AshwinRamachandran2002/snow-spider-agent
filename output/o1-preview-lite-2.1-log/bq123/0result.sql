WITH stats AS (
  SELECT
    FORMAT_DATETIME('%A', q.creation_date) AS Day,
    ROUND(100 * SUM(CASE WHEN TIMESTAMP_DIFF(a.first_answer_date, q.creation_date, SECOND) <= 3600 THEN 1 ELSE 0 END) / COUNT(*), 4) AS Percentage
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  LEFT JOIN (
    SELECT
      parent_id,
      MIN(creation_date) AS first_answer_date
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    GROUP BY parent_id
  ) a ON q.id = a.parent_id
  GROUP BY Day
)
SELECT
  Day,
  Percentage
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY Percentage DESC) AS rn
  FROM stats
)
WHERE rn = 3