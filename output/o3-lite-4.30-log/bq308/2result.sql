WITH first_answer AS (
  SELECT
    parent_id,
    MIN(creation_date) AS first_answer_ts
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),
questions_2021 AS (
  SELECT
    q.id,
    q.creation_date,
    CASE EXTRACT(DAYOFWEEK FROM q.creation_date)
      WHEN 1 THEN 'Sunday'
      WHEN 2 THEN 'Monday'
      WHEN 3 THEN 'Tuesday'
      WHEN 4 THEN 'Wednesday'
      WHEN 5 THEN 'Thursday'
      WHEN 6 THEN 'Friday'
      WHEN 7 THEN 'Saturday'
    END AS day_of_week,
    f.first_answer_ts
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN first_answer AS f
    ON f.parent_id = q.id
  WHERE q.creation_date BETWEEN '2021-01-01' AND '2021-12-31 23:59:59'
)
SELECT
  day_of_week,
  COUNT(*) AS total_questions,
  SUM(
    CASE
      WHEN first_answer_ts IS NOT NULL
           AND TIMESTAMP_DIFF(first_answer_ts, creation_date, MINUTE) <= 60
      THEN 1 ELSE 0
    END
  ) AS answered_within_1h,
  ROUND(
    100 * SAFE_DIVIDE(
      SUM(
        CASE
          WHEN first_answer_ts IS NOT NULL
               AND TIMESTAMP_DIFF(first_answer_ts, creation_date, MINUTE) <= 60
          THEN 1 ELSE 0
        END
      ),
      COUNT(*)
    ),
    4
  ) AS percent_answered_within_1h
FROM questions_2021
GROUP BY day_of_week
ORDER BY
  CASE day_of_week
    WHEN 'Sunday'    THEN 1
    WHEN 'Monday'    THEN 2
    WHEN 'Tuesday'   THEN 3
    WHEN 'Wednesday' THEN 4
    WHEN 'Thursday'  THEN 5
    WHEN 'Friday'    THEN 6
    WHEN 'Saturday'  THEN 7
  END;