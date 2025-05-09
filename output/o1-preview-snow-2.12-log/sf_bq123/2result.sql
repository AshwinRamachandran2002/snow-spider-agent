WITH total_questions AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM TO_TIMESTAMP("creation_date")) AS "day_of_week",
    COUNT(*) AS "total_questions"
  FROM
    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
  GROUP BY
    EXTRACT(DAYOFWEEK FROM TO_TIMESTAMP("creation_date"))
),
questions_answered_within_hour AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM TO_TIMESTAMP(q."creation_date")) AS "day_of_week",
    COUNT(DISTINCT q."id") AS "questions_answered_within_hour"
  FROM
    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
    INNER JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
      ON q."id" = a."parent_id"
  WHERE
    (a."creation_date" - q."creation_date") <= 3600
  GROUP BY
    EXTRACT(DAYOFWEEK FROM TO_TIMESTAMP(q."creation_date"))
)
SELECT
  CASE 
    WHEN t."day_of_week" = 1 THEN 'Sunday'
    WHEN t."day_of_week" = 2 THEN 'Monday'
    WHEN t."day_of_week" = 3 THEN 'Tuesday'
    WHEN t."day_of_week" = 4 THEN 'Wednesday'
    WHEN t."day_of_week" = 5 THEN 'Thursday'
    WHEN t."day_of_week" = 6 THEN 'Friday'
    WHEN t."day_of_week" = 7 THEN 'Saturday'
  END AS "Day",
  ROUND((a."questions_answered_within_hour" * 100.0) / t."total_questions", 4) AS "Percentage"
FROM
  total_questions t
  JOIN questions_answered_within_hour a ON t."day_of_week" = a."day_of_week"
ORDER BY
  "Percentage" DESC NULLS LAST
LIMIT 1 OFFSET 2;